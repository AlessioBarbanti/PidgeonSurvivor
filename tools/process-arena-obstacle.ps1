param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $true)]
    [ValidateRange(8, 2048)]
    [int]$TargetWidth,

    [Parameter(Mandatory = $true)]
    [ValidateRange(8, 2048)]
    [int]$TargetHeight,

    [ValidateRange(1, 255)]
    [int]$VisibleAlphaThreshold = 8,

    [ValidateRange(0, 64)]
    [int]$Padding = 8
)

# Variante non quadrata di process-upgrade-icon.ps1: ritaglia sul bounding
# box alpha (o sull'intera immagine se opaca), applica un padding uniforme e
# riduce con nearest-neighbor a TargetWidth x TargetHeight senza forzare un
# canvas quadrato, cosi' l'aspect ratio di ogni ostacolo resta quello scelto
# in fase di layout invece di quello sorgente.

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

    $left = [Math]::Max($minX - $Padding, 0)
    $top = [Math]::Max($minY - $Padding, 0)
    $right = [Math]::Min($maxX + $Padding, $source.Width - 1)
    $bottom = [Math]::Min($maxY + $Padding, $source.Height - 1)
    $cropWidth = $right - $left + 1
    $cropHeight = $bottom - $top + 1

    $target = New-Object System.Drawing.Bitmap(
        $TargetWidth,
        $TargetHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($target)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighSpeed
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
            $graphics.DrawImage(
                $source,
                (New-Object System.Drawing.Rectangle(0, 0, $TargetWidth, $TargetHeight)),
                (New-Object System.Drawing.Rectangle($left, $top, $cropWidth, $cropHeight)),
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
Write-Output "ARENA_OBSTACLE_RUNTIME_OK path=$($result.FullName) bytes=$($result.Length) sha256=$($hash.Hash)"
