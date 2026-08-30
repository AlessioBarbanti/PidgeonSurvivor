param(
	[Parameter(Mandatory = $true)]
	[string]$InputPath,

	[Parameter(Mandatory = $true)]
	[string]$OutputPath,

	[ValidateRange(16, 256)]
	[int]$Width = 64,

	[ValidateRange(16, 256)]
	[int]$Height = 32,

	[ValidateRange(0, 32)]
	[int]$Padding = 2,

	[ValidateRange(1, 255)]
	[int]$VisibleAlphaThreshold = 32,

	[ValidateRange(0, 254)]
	[int]$TransparentAlphaThreshold = 16,

	[string[]]$Palette = @()
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$paletteColors = @()
foreach ($hexColor in $Palette) {
	if ($hexColor -notmatch '^#[0-9A-Fa-f]{6}$') {
		throw "Palette colors must use #RRGGBB: $hexColor"
	}
	$paletteColors += [System.Drawing.ColorTranslator]::FromHtml($hexColor)
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($outputDirectory)) {
	[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
try {
	$cornerAlpha = @(
		$source.GetPixel(0, 0).A
		$source.GetPixel($source.Width - 1, 0).A
		$source.GetPixel(0, $source.Height - 1).A
		$source.GetPixel($source.Width - 1, $source.Height - 1).A
	)
	if (($cornerAlpha | Measure-Object -Maximum).Maximum -gt 8) {
		throw "Projectile VFX source must have transparent corners: $resolvedInput"
	}

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
		throw "Projectile VFX source has no visible pixels: $resolvedInput"
	}

	$availableWidth = $Width - (2 * $Padding)
	$availableHeight = $Height - (2 * $Padding)
	if ($availableWidth -le 0 -or $availableHeight -le 0) {
		throw "Padding leaves no drawable area."
	}

	$sourceWidth = $maxX - $minX + 1
	$sourceHeight = $maxY - $minY + 1
	$scale = [Math]::Min(
		$availableWidth / [double]$sourceWidth,
		$availableHeight / [double]$sourceHeight
	)
	$targetWidth = [Math]::Max(1, [int][Math]::Round($sourceWidth * $scale))
	$targetHeight = [Math]::Max(1, [int][Math]::Round($sourceHeight * $scale))
	$targetX = [int][Math]::Floor(($Width - $targetWidth) / 2.0)
	$targetY = [int][Math]::Floor(($Height - $targetHeight) / 2.0)

	$target = [System.Drawing.Bitmap]::new(
		$Width,
		$Height,
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
				([System.Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)),
				$minX,
				$minY,
				$sourceWidth,
				$sourceHeight,
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
					continue
				}
				if ($paletteColors.Count -gt 0) {
					$nearestColor = $paletteColors[0]
					$nearestDistance = [double]::MaxValue
					foreach ($paletteColor in $paletteColors) {
						$redDelta = [int]$pixel.R - [int]$paletteColor.R
						$greenDelta = [int]$pixel.G - [int]$paletteColor.G
						$blueDelta = [int]$pixel.B - [int]$paletteColor.B
						$distance = (
							($redDelta * $redDelta) +
							($greenDelta * $greenDelta) +
							($blueDelta * $blueDelta)
						)
						if ($distance -lt $nearestDistance) {
							$nearestDistance = $distance
							$nearestColor = $paletteColor
						}
					}
					$target.SetPixel(
						$x,
						$y,
						[System.Drawing.Color]::FromArgb(
							255,
							$nearestColor.R,
							$nearestColor.G,
							$nearestColor.B
						)
					)
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
Write-Output (
	"PROJECTILE_VFX_RUNTIME_OK path={0} size={1}x{2} palette={3} bytes={4} sha256={5}" -f
	$result.FullName,
	$Width,
	$Height,
	$paletteColors.Count,
	$result.Length,
	$hash.Hash
)
