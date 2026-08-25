param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(10, 100)]
    [int]$ScalePercent = 35,

    [ValidateRange(1, 255)]
    [int]$VisibleAlphaThreshold = 8,

    [ValidateRange(0, 64)]
    [int]$Padding = 4
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
try {
    $minX = $source.Width
    $minY = $source.Height
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            if ($source.GetPixel($x, $y).A -lt $VisibleAlphaThreshold) {
                continue
            }
            $minX = [Math]::Min($minX, $x)
            $minY = [Math]::Min($minY, $y)
            $maxX = [Math]::Max($maxX, $x)
            $maxY = [Math]::Max($maxY, $y)
        }
    }
    if ($maxX -lt $minX -or $maxY -lt $minY) {
        throw "No visible pixels found in $resolvedInput."
    }

    $left = [Math]::Max(0, $minX - $Padding)
    $top = [Math]::Max(0, $minY - $Padding)
    $right = [Math]::Min($source.Width - 1, $maxX + $Padding)
    $bottom = [Math]::Min($source.Height - 1, $maxY + $Padding)
    $cropWidth = $right - $left + 1
    $cropHeight = $bottom - $top + 1
    $targetWidth = [Math]::Max(1, [Math]::Round($cropWidth * $ScalePercent / 100.0))
    $targetHeight = [Math]::Max(1, [Math]::Round($cropHeight * $ScalePercent / 100.0))

    $target = New-Object System.Drawing.Bitmap(
        $targetWidth,
        $targetHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($target)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighSpeed
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
            $destinationRect = New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)
            $sourceRect = New-Object System.Drawing.Rectangle($left, $top, $cropWidth, $cropHeight)
            $graphics.DrawImage(
                $source,
                $destinationRect,
                $sourceRect,
                [System.Drawing.GraphicsUnit]::Pixel
            )
        }
        finally {
            $graphics.Dispose()
        }
        $target.Save($resolvedOutput, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $target.Dispose()
    }
}
finally {
    $source.Dispose()
}

$result = Get-Item -LiteralPath $resolvedOutput
$hash = Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256
Write-Output "CTA_RUNTIME_OK path=$($result.FullName) bytes=$($result.Length) sha256=$($hash.Hash)"
