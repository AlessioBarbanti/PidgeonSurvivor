param(
    [Parameter(Mandatory = $true)]
    [string]$MasterInputPath,

    [Parameter(Mandatory = $true)]
    [string]$WineInputPath,

    [Parameter(Mandatory = $true)]
    [string]$GlassOutputPath,

    [Parameter(Mandatory = $true)]
    [string]$WineOutputPath,

    [ValidateRange(32, 512)]
    [int]$Size = 128
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Convert-LayerToRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [int]$ExpectedWidth,

        [Parameter(Mandatory = $true)]
        [int]$ExpectedHeight,

        [Parameter(Mandatory = $true)]
        [int]$OutputSize
    )

    $resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
    try {
        if ($source.Width -ne $ExpectedWidth -or $source.Height -ne $ExpectedHeight) {
            throw "Layer dimensions must match: $resolvedInput is $($source.Width)x$($source.Height), expected ${ExpectedWidth}x${ExpectedHeight}."
        }

        $target = New-Object System.Drawing.Bitmap(
            $OutputSize,
            $OutputSize,
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
                    (New-Object System.Drawing.Rectangle(0, 0, $OutputSize, $OutputSize)),
                    (New-Object System.Drawing.Rectangle(0, 0, $ExpectedWidth, $ExpectedHeight)),
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
}

function Convert-GlassMasterToRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [int]$OutputSize
    )

    $resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $source = [System.Drawing.Bitmap]::FromFile($resolvedInput)
    try {
        $glassLayer = New-Object System.Drawing.Bitmap(
            $source.Width,
            $source.Height,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            for ($y = 0; $y -lt $source.Height; $y++) {
                for ($x = 0; $x -lt $source.Width; $x++) {
                    $pixel = $source.GetPixel($x, $y)
                    # Il vino e' l'unico gruppo cromatico a rosso dominante; il
                    # contorno prugna, il vetro azzurro e le finiture oro restano.
                    $isWine = $pixel.A -gt 8 -and $pixel.R -gt ($pixel.G * 1.5) -and $pixel.R -gt ($pixel.B * 1.5)
                    if (-not $isWine) {
                        $glassLayer.SetPixel($x, $y, $pixel)
                    }
                }
            }

            $target = New-Object System.Drawing.Bitmap(
                $OutputSize,
                $OutputSize,
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
                        $glassLayer,
                        (New-Object System.Drawing.Rectangle(0, 0, $OutputSize, $OutputSize)),
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
            $glassLayer.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

$glassSource = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $MasterInputPath).Path)
try {
    $sourceWidth = $glassSource.Width
    $sourceHeight = $glassSource.Height
}
finally {
    $glassSource.Dispose()
}

Convert-GlassMasterToRuntime -InputPath $MasterInputPath -OutputPath $GlassOutputPath -OutputSize $Size
Convert-LayerToRuntime -InputPath $WineInputPath -OutputPath $WineOutputPath -ExpectedWidth $sourceWidth -ExpectedHeight $sourceHeight -OutputSize $Size

foreach ($path in @($GlassOutputPath, $WineOutputPath)) {
    $result = Get-Item -LiteralPath $path
    $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
    Write-Output "LAYERED_HUD_ICON_RUNTIME_OK path=$($result.FullName) bytes=$($result.Length) sha256=$($hash.Hash)"
}
