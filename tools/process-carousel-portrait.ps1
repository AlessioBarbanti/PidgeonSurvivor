param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(64, 1024)]
    [int]$CanvasSize = 256,

    [ValidateRange(0, 128)]
    [int]$Padding = 14,

    [ValidateRange(1, 255)]
    [int]$VisibleAlphaThreshold = 8
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not ("CarouselPortraitBounds" -as [type])) {
    $drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
    Add-Type -ReferencedAssemblies $drawingAssembly -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CarouselPortraitBounds
{
    public static Rectangle GetVisibleBounds(Bitmap source, Rectangle cell, byte alphaThreshold)
    {
        BitmapData data = source.LockBits(cell, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int stride = cell.Width * 4;
        byte[] pixels = new byte[stride * cell.Height];
        try
        {
            for (int y = 0; y < cell.Height; y++)
            {
                IntPtr row = IntPtr.Add(data.Scan0, y * data.Stride);
                Marshal.Copy(row, pixels, y * stride, stride);
            }
        }
        finally
        {
            source.UnlockBits(data);
        }

        bool[] visited = new bool[cell.Width * cell.Height];
        Rectangle largest = Rectangle.Empty;
        int largestArea = 0;
        var queue = new Queue<int>();
        int[] deltaX = new int[] { -1, 1, 0, 0 };
        int[] deltaY = new int[] { 0, 0, -1, 1 };
        for (int y = 0; y < cell.Height; y++)
        {
            for (int x = 0; x < cell.Width; x++)
            {
                int start = (y * cell.Width) + x;
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
                    int currentX = current % cell.Width;
                    int currentY = current / cell.Width;
                    area++;
                    minX = Math.Min(minX, currentX);
                    maxX = Math.Max(maxX, currentX);
                    minY = Math.Min(minY, currentY);
                    maxY = Math.Max(maxY, currentY);

                    for (int direction = 0; direction < 4; direction++)
                    {
                        int nextX = currentX + deltaX[direction];
                        int nextY = currentY + deltaY[direction];
                        if (nextX < 0 || nextX >= cell.Width || nextY < 0 || nextY >= cell.Height)
                            continue;
                        int next = (nextY * cell.Width) + nextX;
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
                        cell.X + minX,
                        cell.Y + minY,
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
    if (($source.Width % 3) -ne 0) {
        throw "Source width $($source.Width) is not divisible by three frames."
    }
    $cellWidth = [int]($source.Width / 3)
    $idleCell = [System.Drawing.Rectangle]::new($cellWidth, 0, $cellWidth, $source.Height)
    $visibleBounds = [CarouselPortraitBounds]::GetVisibleBounds(
        $source,
        $idleCell,
        [byte]$VisibleAlphaThreshold
    )
    if ($visibleBounds.IsEmpty) {
        throw "The idle frame has no visible pixels."
    }

    $availableSize = $CanvasSize - (2 * $Padding)
    $scale = [Math]::Min(
        $availableSize / [double]$visibleBounds.Width,
        $availableSize / [double]$visibleBounds.Height
    )
    $targetWidth = [Math]::Max(1, [int][Math]::Round($visibleBounds.Width * $scale))
    $targetHeight = [Math]::Max(1, [int][Math]::Round($visibleBounds.Height * $scale))
    $targetX = [int][Math]::Floor(($CanvasSize - $targetWidth) / 2.0)
    $targetY = $CanvasSize - $Padding - $targetHeight

    $destination = [System.Drawing.Bitmap]::new(
        $CanvasSize,
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
            $targetRect = [System.Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)
            $graphics.DrawImage(
                $source,
                $targetRect,
                $visibleBounds.X,
                $visibleBounds.Y,
                $visibleBounds.Width,
                $visibleBounds.Height,
                [System.Drawing.GraphicsUnit]::Pixel
            )
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

Write-Output (
    "CAROUSEL_PORTRAIT_PROCESSED path={0} source={1} target={2}x{3}" -f
    $resolvedOutput,
    $visibleBounds,
    $targetWidth,
    $targetHeight
)
