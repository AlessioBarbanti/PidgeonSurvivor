param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(0.1, 1.0)]
    [double]$Scale = 0.5
)

# PS-176: ritratto Boss "fluttuante" mostrato per intero (nessun crop, nessuna
# distorsione). A differenza di process-upgrade-icon.ps1/process-arena-obstacle.ps1
# non ritaglia sui bounds alpha: l'intera tela dipinta (ornamentazione compresa)
# e' contenuto valido e va preservata byte-a-byte come rapporto d'aspetto, cosi'
# le percentuali del cartiglio misurate sul master restano valide sul derivato.
# Ricampionamento bicubico (non nearest-neighbor): sorgente pittorica, non pixel-art.

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
    $targetWidth = [Math]::Max(1, [Math]::Round($source.Width * $Scale))
    $targetHeight = [Math]::Max(1, [Math]::Round($source.Height * $Scale))

    $target = New-Object System.Drawing.Bitmap(
        $targetWidth,
        $targetHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($target)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
            $graphics.DrawImage(
                $source,
                (New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)),
                (New-Object System.Drawing.Rectangle(0, 0, $source.Width, $source.Height)),
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
Write-Output "BOSS_PORTRAIT_RUNTIME_OK path=$($result.FullName) bytes=$($result.Length) sha256=$($hash.Hash)"
