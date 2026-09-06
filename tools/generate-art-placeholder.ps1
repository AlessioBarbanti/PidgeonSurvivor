param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8192)]
    [int]$Width,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8192)]
    [int]$Height,

    [string]$Label = "PLACEHOLDER",

    [ValidateRange(4, 512)]
    [int]$CellSize = 32,

    # Ritaglio rettangolare reso trasparente (alpha 0): "x,y,w,h" in pixel.
    [string]$HoleRect,

    # Ritaglio circolare reso trasparente (alpha 0): "cx,cy,r" in pixel.
    [string]$HoleCircle
)

# PS-110: placeholder deterministico per una card di integrazione che deve
# poter procedere (IN ATTESA ASSET) prima che l'asset reale esista. La
# firma di riconoscimento non e' l'hash del file (il rendering del testo
# via GDI+ non e' garantito byte-identico fra macchine/versioni), ma il
# pixel (0,0): la scacchiera parte sempre da una cella magenta piena
# (255,0,255,255), un colore che nessun asset reale dovrebbe avere esatto
# in quel punto. Il gate di chiusura della card verifica quel solo pixel.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Parse-Region([string]$Value, [int]$ExpectedParts) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }
    $parts = $Value.Split(",") | ForEach-Object { $_.Trim() }
    if ($parts.Count -ne $ExpectedParts) {
        throw "Formato non valido: '$Value' (attesi $ExpectedParts valori separati da virgola)."
    }
    return ,($parts | ForEach-Object { [double]$_ })
}

$holeRectValues = Parse-Region -Value $HoleRect -ExpectedParts 4
$holeCircleValues = Parse-Region -Value $HoleCircle -ExpectedParts 3

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$magenta = [System.Drawing.Color]::FromArgb(255, 255, 0, 255)
$black = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

$bitmap = New-Object System.Drawing.Bitmap(
    $Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
try {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

        # Scacchiera: la cella (0,0) e' sempre magenta piena, per costruzione.
        $magentaBrush = New-Object System.Drawing.SolidBrush($magenta)
        $blackBrush = New-Object System.Drawing.SolidBrush($black)
        try {
            for ($cellY = 0; $cellY * $CellSize -lt $Height; $cellY++) {
                for ($cellX = 0; $cellX * $CellSize -lt $Width; $cellX++) {
                    $brush = if ((($cellX + $cellY) % 2) -eq 0) { $magentaBrush } else { $blackBrush }
                    $rect = New-Object System.Drawing.Rectangle(
                        ($cellX * $CellSize), ($cellY * $CellSize), $CellSize, $CellSize
                    )
                    $graphics.FillRectangle($brush, $rect)
                }
            }
        }
        finally {
            $magentaBrush.Dispose()
            $blackBrush.Dispose()
        }

        # Etichetta diagonale ripetuta: solo per riconoscimento a occhio nelle
        # catture, non parte della verifica automatica (il rendering del testo
        # non e' garantito identico fra ambienti).
        if (-not [string]::IsNullOrWhiteSpace($Label)) {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $font = New-Object System.Drawing.Font("Consolas", [Math]::Max(10, [Math]::Min($Width, $Height) / 12), [System.Drawing.FontStyle]::Bold)
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
            try {
                $graphics.TranslateTransform($Width / 2.0, $Height / 2.0)
                $graphics.RotateTransform(-30)
                $textSize = $graphics.MeasureString($Label, $font)
                $stepX = $textSize.Width + 24
                $stepY = $textSize.Height + 24
                $span = [Math]::Max($Width, $Height) * 1.5
                for ($y = -$span; $y -lt $span; $y += $stepY) {
                    for ($x = -$span; $x -lt $span; $x += $stepX) {
                        $graphics.DrawString($Label, $font, $textBrush, [single]$x, [single]$y)
                    }
                }
                $graphics.ResetTransform()
            }
            finally {
                $font.Dispose()
                $textBrush.Dispose()
            }
        }

        # Ritagli trasparenti: SourceCopy forza alpha 0 reale, non un blend.
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $transparentBrush = New-Object System.Drawing.SolidBrush($transparent)
        try {
            if ($null -ne $holeRectValues) {
                $rect = New-Object System.Drawing.RectangleF(
                    $holeRectValues[0], $holeRectValues[1], $holeRectValues[2], $holeRectValues[3]
                )
                $graphics.FillRectangle($transparentBrush, $rect)
            }
            if ($null -ne $holeCircleValues) {
                $cx = $holeCircleValues[0]
                $cy = $holeCircleValues[1]
                $r = $holeCircleValues[2]
                $ellipse = New-Object System.Drawing.RectangleF(($cx - $r), ($cy - $r), ($r * 2), ($r * 2))
                $graphics.FillEllipse($transparentBrush, $ellipse)
            }
        }
        finally {
            $transparentBrush.Dispose()
        }
    }
    finally {
        $graphics.Dispose()
    }

    $bitmap.Save($resolvedOutput, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $bitmap.Dispose()
}

$result = Get-Item -LiteralPath $resolvedOutput
$hash = Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256
Write-Output "PLACEHOLDER_OK path=$($result.FullName) width=$Width height=$Height bytes=$($result.Length) sha256=$($hash.Hash)"
