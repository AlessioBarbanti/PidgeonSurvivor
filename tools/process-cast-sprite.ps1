param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(1, 16)]
    [int]$FrameCount = 3,

    [ValidateRange(8, 256)]
    [int]$CanvasSize = 32,

    [ValidateRange(0, 32)]
    [int]$Padding = 2,

    [ValidateRange(1, 255)]
    [int]$VisibleAlphaThreshold = 192,

    # Trattamento di leggibilita opt-in (PS-132): riduzione che conserva la
    # massa, soglia alfa finale, quantizzazione palette e contorno scuro.
    # Disattivato di default: senza questo switch l'output resta
    # byte-identico al comportamento storico (nearest-neighbor secco).
    [switch]$ReadabilityTreatment,

    [ValidateRange(2, 64)]
    [int]$PaletteColors = 16,

    [ValidateRange(1, 255)]
    [int]$FinalAlphaThreshold = 140,

    [ValidateRange(0.0, 1.0)]
    [double]$OutlineDarkenFactor = 0.35,

    [ValidateRange(1, 4)]
    [int]$OutlineThickness = 1
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not ("CastSpriteBounds" -as [type])) {
    $drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
    Add-Type -ReferencedAssemblies $drawingAssembly -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CastSpriteBounds
{
    public static Rectangle GetLargestComponent(
        Bitmap source,
        int cellX,
        int cellWidth,
        byte alphaThreshold)
    {
        int height = source.Height;
        var cell = new Rectangle(cellX, 0, cellWidth, height);
        BitmapData data = source.LockBits(
            cell,
            ImageLockMode.ReadOnly,
            PixelFormat.Format32bppArgb);
        int stride = cellWidth * 4;
        byte[] pixels = new byte[stride * height];
        try
        {
            for (int y = 0; y < height; y++)
            {
                IntPtr row = IntPtr.Add(data.Scan0, y * data.Stride);
                Marshal.Copy(row, pixels, y * stride, stride);
            }
        }
        finally
        {
            source.UnlockBits(data);
        }

        bool[] visited = new bool[cellWidth * height];
        Rectangle largest = Rectangle.Empty;
        int largestArea = 0;
        var queue = new Queue<int>();
        int[] deltaX = new int[] { -1, 1, 0, 0 };
        int[] deltaY = new int[] { 0, 0, -1, 1 };

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < cellWidth; x++)
            {
                int start = (y * cellWidth) + x;
                if (visited[start])
                    continue;
                visited[start] = true;
                if (pixels[(y * stride) + (x * 4) + 3] < alphaThreshold)
                    continue;

                queue.Enqueue(start);
                int area = 0;
                int minX = x;
                int maxX = x;
                int minY = y;
                int maxY = y;

                while (queue.Count > 0)
                {
                    int current = queue.Dequeue();
                    int currentX = current % cellWidth;
                    int currentY = current / cellWidth;
                    area++;
                    minX = Math.Min(minX, currentX);
                    maxX = Math.Max(maxX, currentX);
                    minY = Math.Min(minY, currentY);
                    maxY = Math.Max(maxY, currentY);

                    for (int direction = 0; direction < 4; direction++)
                    {
                        int nextX = currentX + deltaX[direction];
                        int nextY = currentY + deltaY[direction];
                        if (nextX < 0 || nextX >= cellWidth || nextY < 0 || nextY >= height)
                            continue;
                        int next = (nextY * cellWidth) + nextX;
                        if (visited[next])
                            continue;
                        visited[next] = true;
                        if (pixels[(nextY * stride) + (nextX * 4) + 3] >= alphaThreshold)
                            queue.Enqueue(next);
                    }
                }

                if (area > largestArea)
                {
                    largestArea = area;
                    largest = new Rectangle(
                        cellX + minX,
                        minY,
                        maxX - minX + 1,
                        maxY - minY + 1);
                }
            }
        }

        return largest;
    }
}
"@
}

if (-not ("CastSpriteReadability" -as [type])) {
    $drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
    Add-Type -ReferencedAssemblies $drawingAssembly -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CastSpriteReadability
{
    private struct ColorEntry
    {
        public byte R;
        public byte G;
        public byte B;
        public int Count;
    }

    // Downscale che conserva la massa dei pixel sorgente: ogni pixel di
    // destinazione e la media dell'area sorgente che copre (box filter con
    // peso di sovrapposizione frazionario), colore mediato pesato sull'alfa
    // per evitare frangia scura dai pixel trasparenti circostanti.
    public static Bitmap DownscaleAreaAverage(
        Bitmap source,
        Rectangle sourceRect,
        int targetWidth,
        int targetHeight)
    {
        BitmapData srcData = source.LockBits(
            sourceRect,
            ImageLockMode.ReadOnly,
            PixelFormat.Format32bppArgb);
        byte[] srcPixels = new byte[srcData.Stride * sourceRect.Height];
        try
        {
            Marshal.Copy(srcData.Scan0, srcPixels, 0, srcPixels.Length);
        }
        finally
        {
            source.UnlockBits(srcData);
        }
        int srcStride = srcData.Stride;
        int srcWidth = sourceRect.Width;
        int srcHeight = sourceRect.Height;

        double scaleX = (double)srcWidth / targetWidth;
        double scaleY = (double)srcHeight / targetHeight;

        Bitmap dest = new Bitmap(targetWidth, targetHeight, PixelFormat.Format32bppArgb);
        BitmapData destData = dest.LockBits(
            new Rectangle(0, 0, targetWidth, targetHeight),
            ImageLockMode.WriteOnly,
            PixelFormat.Format32bppArgb);
        byte[] destPixels = new byte[destData.Stride * targetHeight];

        for (int ty = 0; ty < targetHeight; ty++)
        {
            double sy0 = ty * scaleY;
            double sy1 = (ty + 1) * scaleY;
            int syStart = Math.Max(0, (int)Math.Floor(sy0));
            int syEnd = Math.Min(srcHeight - 1, (int)Math.Ceiling(sy1) - 1);

            for (int tx = 0; tx < targetWidth; tx++)
            {
                double sx0 = tx * scaleX;
                double sx1 = (tx + 1) * scaleX;
                int sxStart = Math.Max(0, (int)Math.Floor(sx0));
                int sxEnd = Math.Min(srcWidth - 1, (int)Math.Ceiling(sx1) - 1);

                double weightSum = 0.0;
                double alphaSum = 0.0;
                double colorWeightSum = 0.0;
                double rSum = 0.0;
                double gSum = 0.0;
                double bSum = 0.0;

                for (int sy = syStart; sy <= syEnd; sy++)
                {
                    double wy = Math.Min(sy + 1, sy1) - Math.Max(sy, sy0);
                    if (wy <= 0) continue;
                    for (int sx = sxStart; sx <= sxEnd; sx++)
                    {
                        double wx = Math.Min(sx + 1, sx1) - Math.Max(sx, sx0);
                        if (wx <= 0) continue;
                        double w = wx * wy;

                        int idx = (sy * srcStride) + (sx * 4);
                        byte b = srcPixels[idx];
                        byte g = srcPixels[idx + 1];
                        byte r = srcPixels[idx + 2];
                        byte a = srcPixels[idx + 3];

                        weightSum += w;
                        alphaSum += w * a;
                        double cw = w * (a / 255.0);
                        colorWeightSum += cw;
                        rSum += cw * r;
                        gSum += cw * g;
                        bSum += cw * b;
                    }
                }

                byte destA = 0;
                byte destR = 0;
                byte destG = 0;
                byte destB = 0;
                if (weightSum > 0)
                {
                    destA = (byte)Math.Max(0, Math.Min(255, (int)Math.Round(alphaSum / weightSum)));
                }
                if (colorWeightSum > 1e-6)
                {
                    destR = (byte)Math.Max(0, Math.Min(255, (int)Math.Round(rSum / colorWeightSum)));
                    destG = (byte)Math.Max(0, Math.Min(255, (int)Math.Round(gSum / colorWeightSum)));
                    destB = (byte)Math.Max(0, Math.Min(255, (int)Math.Round(bSum / colorWeightSum)));
                }

                int destIdx = (ty * destData.Stride) + (tx * 4);
                destPixels[destIdx] = destB;
                destPixels[destIdx + 1] = destG;
                destPixels[destIdx + 2] = destR;
                destPixels[destIdx + 3] = destA;
            }
        }

        Marshal.Copy(destPixels, 0, destData.Scan0, destPixels.Length);
        dest.UnlockBits(destData);
        return dest;
    }

    // Binarizza l'alfa (bordi netti da pixel art, niente frangia sfumata).
    // I pixel che scendono sotto soglia diventano interamente trasparenti,
    // cosi' non restano tracce di colore residuo sotto la soglia.
    public static void ThresholdAlpha(Bitmap frame, byte threshold)
    {
        Rectangle rect = new Rectangle(0, 0, frame.Width, frame.Height);
        BitmapData data = frame.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        byte[] pixels = new byte[data.Stride * frame.Height];
        try
        {
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
            for (int y = 0; y < frame.Height; y++)
            {
                for (int x = 0; x < frame.Width; x++)
                {
                    int idx = (y * data.Stride) + (x * 4);
                    if (pixels[idx + 3] >= threshold)
                    {
                        pixels[idx + 3] = 255;
                    }
                    else
                    {
                        pixels[idx] = 0;
                        pixels[idx + 1] = 0;
                        pixels[idx + 2] = 0;
                        pixels[idx + 3] = 0;
                    }
                }
            }
            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
        }
        finally
        {
            frame.UnlockBits(data);
        }
    }

    // Quantizza la palette dei pixel opachi a al massimo maxColors toni
    // piatti (median-cut) e restituisce il colore dominante (piu diffuso).
    // Se i colori distinti sono gia' entro il limite non tocca nulla.
    public static Color Quantize(Bitmap frame, int maxColors)
    {
        Rectangle rect = new Rectangle(0, 0, frame.Width, frame.Height);
        BitmapData data = frame.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        byte[] pixels = new byte[data.Stride * frame.Height];
        Color dominant = Color.Black;
        try
        {
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);

            Dictionary<int, int> counts = new Dictionary<int, int>();
            for (int y = 0; y < frame.Height; y++)
            {
                for (int x = 0; x < frame.Width; x++)
                {
                    int idx = (y * data.Stride) + (x * 4);
                    if (pixels[idx + 3] != 255) continue;
                    int key = (pixels[idx + 2] << 16) | (pixels[idx + 1] << 8) | pixels[idx];
                    int existing;
                    counts.TryGetValue(key, out existing);
                    counts[key] = existing + 1;
                }
            }

            if (counts.Count == 0)
            {
                return dominant;
            }

            List<ColorEntry> entries = new List<ColorEntry>();
            foreach (KeyValuePair<int, int> pair in counts)
            {
                entries.Add(new ColorEntry
                {
                    R = (byte)((pair.Key >> 16) & 0xFF),
                    G = (byte)((pair.Key >> 8) & 0xFF),
                    B = (byte)(pair.Key & 0xFF),
                    Count = pair.Value
                });
            }

            Dictionary<int, Color> remap = new Dictionary<int, Color>();
            int bestCount = -1;

            if (entries.Count <= maxColors)
            {
                foreach (ColorEntry e in entries)
                {
                    int key = (e.R << 16) | (e.G << 8) | e.B;
                    remap[key] = Color.FromArgb(255, e.R, e.G, e.B);
                    if (e.Count > bestCount)
                    {
                        bestCount = e.Count;
                        dominant = remap[key];
                    }
                }
            }
            else
            {
                List<List<ColorEntry>> boxes = new List<List<ColorEntry>> { entries };
                while (boxes.Count < maxColors)
                {
                    int splitIndex = -1;
                    int splitPopulation = -1;
                    for (int i = 0; i < boxes.Count; i++)
                    {
                        if (boxes[i].Count < 2) continue;
                        int population = 0;
                        foreach (ColorEntry e in boxes[i]) population += e.Count;
                        if (population > splitPopulation)
                        {
                            splitPopulation = population;
                            splitIndex = i;
                        }
                    }
                    if (splitIndex < 0) break;

                    List<ColorEntry> box = boxes[splitIndex];
                    byte minR = 255, maxR = 0, minG = 255, maxG = 0, minB = 255, maxB = 0;
                    foreach (ColorEntry e in box)
                    {
                        if (e.R < minR) minR = e.R;
                        if (e.R > maxR) maxR = e.R;
                        if (e.G < minG) minG = e.G;
                        if (e.G > maxG) maxG = e.G;
                        if (e.B < minB) minB = e.B;
                        if (e.B > maxB) maxB = e.B;
                    }
                    int rangeR = maxR - minR;
                    int rangeG = maxG - minG;
                    int rangeB = maxB - minB;

                    Comparison<ColorEntry> comparer;
                    if (rangeR >= rangeG && rangeR >= rangeB)
                        comparer = (a, b) => a.R.CompareTo(b.R);
                    else if (rangeG >= rangeB)
                        comparer = (a, b) => a.G.CompareTo(b.G);
                    else
                        comparer = (a, b) => a.B.CompareTo(b.B);
                    box.Sort(comparer);

                    int total = 0;
                    foreach (ColorEntry e in box) total += e.Count;
                    int half = total / 2;
                    int cumulative = 0;
                    int cutAt = box.Count - 1;
                    for (int i = 0; i < box.Count; i++)
                    {
                        cumulative += box[i].Count;
                        if (cumulative >= half)
                        {
                            cutAt = i;
                            break;
                        }
                    }
                    if (cutAt >= box.Count - 1) cutAt = box.Count - 2;
                    if (cutAt < 0) cutAt = 0;

                    List<ColorEntry> left = box.GetRange(0, cutAt + 1);
                    List<ColorEntry> right = box.GetRange(cutAt + 1, box.Count - cutAt - 1);
                    boxes.RemoveAt(splitIndex);
                    boxes.Add(left);
                    if (right.Count > 0) boxes.Add(right);
                }

                foreach (List<ColorEntry> box in boxes)
                {
                    long rSum = 0, gSum = 0, bSum = 0;
                    int total = 0;
                    foreach (ColorEntry e in box)
                    {
                        rSum += (long)e.R * e.Count;
                        gSum += (long)e.G * e.Count;
                        bSum += (long)e.B * e.Count;
                        total += e.Count;
                    }
                    if (total == 0) continue;
                    Color avg = Color.FromArgb(
                        255,
                        (int)(rSum / total),
                        (int)(gSum / total),
                        (int)(bSum / total));
                    foreach (ColorEntry e in box)
                    {
                        int key = (e.R << 16) | (e.G << 8) | e.B;
                        remap[key] = avg;
                    }
                    if (total > bestCount)
                    {
                        bestCount = total;
                        dominant = avg;
                    }
                }
            }

            for (int y = 0; y < frame.Height; y++)
            {
                for (int x = 0; x < frame.Width; x++)
                {
                    int idx = (y * data.Stride) + (x * 4);
                    if (pixels[idx + 3] != 255) continue;
                    int key = (pixels[idx + 2] << 16) | (pixels[idx + 1] << 8) | pixels[idx];
                    Color mapped;
                    if (remap.TryGetValue(key, out mapped))
                    {
                        pixels[idx] = mapped.B;
                        pixels[idx + 1] = mapped.G;
                        pixels[idx + 2] = mapped.R;
                    }
                }
            }
            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
        }
        finally
        {
            frame.UnlockBits(data);
        }
        return dominant;
    }

    // Fa crescere un anello di contorno di 1px attorno alla sagoma opaca
    // (connettivita a 8), usando un'istantanea della maschera opaca presa
    // prima della modifica: copertura del perimetro senza propagazione a
    // catena oltre il primo anello.
    public static void ApplyOutline(Bitmap frame, Color outlineColor)
    {
        Rectangle rect = new Rectangle(0, 0, frame.Width, frame.Height);
        BitmapData data = frame.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int width = frame.Width;
        int height = frame.Height;
        byte[] pixels = new byte[data.Stride * height];
        try
        {
            Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);

            bool[] opaque = new bool[width * height];
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int idx = (y * data.Stride) + (x * 4);
                    opaque[(y * width) + x] = pixels[idx + 3] == 255;
                }
            }

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    if (opaque[(y * width) + x]) continue;
                    bool touchesOpaque = false;
                    for (int dy = -1; dy <= 1 && !touchesOpaque; dy++)
                    {
                        int ny = y + dy;
                        if (ny < 0 || ny >= height) continue;
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            if (dx == 0 && dy == 0) continue;
                            int nx = x + dx;
                            if (nx < 0 || nx >= width) continue;
                            if (opaque[(ny * width) + nx])
                            {
                                touchesOpaque = true;
                                break;
                            }
                        }
                    }
                    if (touchesOpaque)
                    {
                        int idx = (y * data.Stride) + (x * 4);
                        pixels[idx] = outlineColor.B;
                        pixels[idx + 1] = outlineColor.G;
                        pixels[idx + 2] = outlineColor.R;
                        pixels[idx + 3] = 255;
                    }
                }
            }

            Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
        }
        finally
        {
            frame.UnlockBits(data);
        }
    }
}
"@
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($outputDirectory)) {
    [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

function Get-DarkenedColor {
    param(
        [System.Drawing.Color]$Color,
        [double]$Factor
    )
    $r = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($Color.R * $Factor)))
    $g = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($Color.G * $Factor)))
    $b = [Math]::Max(0, [Math]::Min(255, [int][Math]::Round($Color.B * $Factor)))
    return [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
}

$source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
try {
    if (($source.Width % $FrameCount) -ne 0) {
        throw "Source width $($source.Width) is not divisible by $FrameCount frames."
    }

    $cellWidth = [int]($source.Width / $FrameCount)
    $outlineReserve = if ($ReadabilityTreatment) { $OutlineThickness } else { 0 }
    $availableSize = $CanvasSize - (2 * $Padding) - (2 * $outlineReserve)
    if ($availableSize -le 0) {
        throw "Padding leaves no drawable area."
    }

    $destination = [System.Drawing.Bitmap]::new(
        $CanvasSize * $FrameCount,
        $CanvasSize,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($destination)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighSpeed
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

            for ($frameIndex = 0; $frameIndex -lt $FrameCount; $frameIndex++) {
                $cellX = $frameIndex * $cellWidth
                $componentBounds = [CastSpriteBounds]::GetLargestComponent(
                    $source,
                    $cellX,
                    $cellWidth,
                    [byte]$VisibleAlphaThreshold
                )
                if ($componentBounds.IsEmpty) {
                    throw "Frame $frameIndex has no visible pixels."
                }

                $minX = $componentBounds.X
                $minY = $componentBounds.Y
                $sourceWidth = $componentBounds.Width
                $sourceHeight = $componentBounds.Height
                $scale = [Math]::Min(
                    $availableSize / [double]$sourceWidth,
                    $availableSize / [double]$sourceHeight
                )
                $targetWidth = [Math]::Max(1, [int][Math]::Round($sourceWidth * $scale))
                $targetHeight = [Math]::Max(1, [int][Math]::Round($sourceHeight * $scale))

                if ($ReadabilityTreatment) {
                    $sourceRect = [System.Drawing.Rectangle]::new($minX, $minY, $sourceWidth, $sourceHeight)
                    $frameBitmap = [CastSpriteReadability]::DownscaleAreaAverage(
                        $source, $sourceRect, $targetWidth, $targetHeight
                    )
                    $padded = $null
                    try {
                        [CastSpriteReadability]::ThresholdAlpha($frameBitmap, [byte]$FinalAlphaThreshold)
                        $dominant = [CastSpriteReadability]::Quantize($frameBitmap, $PaletteColors)
                        $outlineColor = Get-DarkenedColor -Color $dominant -Factor $OutlineDarkenFactor

                        $paddedWidth = $targetWidth + (2 * $outlineReserve)
                        $paddedHeight = $targetHeight + (2 * $outlineReserve)
                        $padded = [System.Drawing.Bitmap]::new(
                            $paddedWidth, $paddedHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
                        )
                        $paddedGraphics = [System.Drawing.Graphics]::FromImage($padded)
                        try {
                            $paddedGraphics.Clear([System.Drawing.Color]::Transparent)
                            $paddedGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                            $paddedGraphics.DrawImageUnscaled($frameBitmap, $outlineReserve, $outlineReserve)
                        }
                        finally {
                            $paddedGraphics.Dispose()
                        }
                        for ($ring = 0; $ring -lt $OutlineThickness; $ring++) {
                            [CastSpriteReadability]::ApplyOutline($padded, $outlineColor)
                        }

                        $targetX = ($frameIndex * $CanvasSize) + [int][Math]::Floor(($CanvasSize - $paddedWidth) / 2.0)
                        $targetY = $CanvasSize - $Padding - $paddedHeight
                        $graphics.DrawImageUnscaled($padded, $targetX, $targetY)

                        Write-Output (
                            "frame={0} source={1}x{2} target={3}x{4} offset={5},{6} readability=1 palette_dominant=#{7:X2}{8:X2}{9:X2} outline=#{10:X2}{11:X2}{12:X2}" -f
                            $frameIndex,
                            $sourceWidth,
                            $sourceHeight,
                            $paddedWidth,
                            $paddedHeight,
                            ($targetX - ($frameIndex * $CanvasSize)),
                            $targetY,
                            $dominant.R, $dominant.G, $dominant.B,
                            $outlineColor.R, $outlineColor.G, $outlineColor.B
                        )
                    }
                    finally {
                        $frameBitmap.Dispose()
                        if ($padded -ne $null) { $padded.Dispose() }
                    }
                }
                else {
                    $targetX = ($frameIndex * $CanvasSize) + [int][Math]::Floor(($CanvasSize - $targetWidth) / 2.0)
                    $targetY = $CanvasSize - $Padding - $targetHeight

                    $sourceRect = [System.Drawing.Rectangle]::new($minX, $minY, $sourceWidth, $sourceHeight)
                    $targetRect = [System.Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)
                    $graphics.DrawImage(
                        $source,
                        $targetRect,
                        $sourceRect.X,
                        $sourceRect.Y,
                        $sourceRect.Width,
                        $sourceRect.Height,
                        [System.Drawing.GraphicsUnit]::Pixel
                    )

                    Write-Output (
                        "frame={0} source={1}x{2} target={3}x{4} offset={5},{6}" -f
                        $frameIndex,
                        $sourceWidth,
                        $sourceHeight,
                        $targetWidth,
                        $targetHeight,
                        ($targetX - ($frameIndex * $CanvasSize)),
                        $targetY
                    )
                }
            }
        }
        finally {
            $graphics.Dispose()
        }

        $destination.Save($resolvedOutput, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $destination.Dispose()
    }
}
finally {
    $source.Dispose()
}

Write-Output "CAST_SPRITE_PROCESSED path=$resolvedOutput"
