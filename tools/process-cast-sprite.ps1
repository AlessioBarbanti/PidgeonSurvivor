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
    [int]$VisibleAlphaThreshold = 192
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

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($outputDirectory)) {
    [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
try {
    if (($source.Width % $FrameCount) -ne 0) {
        throw "Source width $($source.Width) is not divisible by $FrameCount frames."
    }

    $cellWidth = [int]($source.Width / $FrameCount)
    $availableSize = $CanvasSize - (2 * $Padding)
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
