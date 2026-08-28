param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

	[ValidateRange(128, 1024)]
	[int]$Size = 512,

	[ValidateRange(0, 254)]
	[int]$TransparentAlphaThreshold = 32
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
    if ($source.Width -ne $source.Height) {
        throw "Ability VFX source must use a square canvas: $resolvedInput"
    }

    $cornerAlpha = @(
        $source.GetPixel(0, 0).A
        $source.GetPixel($source.Width - 1, 0).A
        $source.GetPixel(0, $source.Height - 1).A
        $source.GetPixel($source.Width - 1, $source.Height - 1).A
    )
    if (($cornerAlpha | Measure-Object -Maximum).Maximum -gt 8) {
        throw "Ability VFX source must have transparent corners: $resolvedInput"
    }

    $target = New-Object System.Drawing.Bitmap(
        $Size,
        $Size,
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
                (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)),
                (New-Object System.Drawing.Rectangle(0, 0, $source.Width, $source.Height)),
                [System.Drawing.GraphicsUnit]::Pixel
            )
        }
		finally {
			$graphics.Dispose()
		}
		for ($y = 0; $y -lt $target.Height; $y++) {
			for ($x = 0; $x -lt $target.Width; $x++) {
				$pixel = $target.GetPixel($x, $y)
				if ($pixel.A -lt $TransparentAlphaThreshold) {
					$target.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
				}
			}
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
Write-Output "ABILITY_VFX_RUNTIME_OK path=$($result.FullName) bytes=$($result.Length) sha256=$($hash.Hash)"
