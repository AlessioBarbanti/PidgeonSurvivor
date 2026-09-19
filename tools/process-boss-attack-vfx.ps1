param(
    [string]$AssetRoot = "assets/art/vfx/boss_attacks"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

# PS-144: coordinate canoniche stabili per allineare il disegno al danno.
foreach ($name in @("danger_ring", "blast", "reticle", "corridor")) {
    $source = [Drawing.Bitmap]::FromFile((Resolve-Path "$AssetRoot/hd/boss_${name}_source.png").Path)
    $size = 512
    if ($name -eq "reticle") { $size = 128 }
    $target = New-Object Drawing.Bitmap($size, $size, ([Drawing.Imaging.PixelFormat]::Format32bppArgb))
    try {
        if ($source.GetPixel(0,0).A -ne 0) { throw "Master senza alpha: $name" }
        $minX=$source.Width; $minY=$source.Height; $maxX=0; $maxY=0
        for ($y=0; $y -lt $source.Height; $y++) {
            for ($x=0; $x -lt $source.Width; $x++) {
                if ($source.GetPixel($x,$y).A -lt 32) { continue }
                $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y)
                $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y)
            }
        }
        $cx=($minX+$maxX)/2.0; $cy=($minY+$maxY)/2.0
        $radius=0.0
        for ($y=$minY; $y -le $maxY; $y++) {
            for ($x=$minX; $x -le $maxX; $x++) {
                if ($source.GetPixel($x,$y).A -lt 32) { continue }
                $radius=[Math]::Max($radius,[Math]::Sqrt(($x-$cx)*($x-$cx)+($y-$cy)*($y-$cy)))
            }
        }
        $scale=($size*0.46-1)/$radius
        if ($name -eq "corridor") { $scale=($size*0.92-2)/($maxX-$minX+1) }
        $alphaCount=0; $outMinX=$size; $outMinY=$size; $outMaxX=0; $outMaxY=0
        for ($y=0; $y -lt $size; $y++) {
            for ($x=0; $x -lt $size; $x++) {
                $dx=$x+0.5-$size/2.0; $dy=$y+0.5-$size/2.0
                if ($name -ne "corridor" -and ($dx*$dx+$dy*$dy) -gt [Math]::Pow($size*0.46,2)) { continue }
                $sx=[int][Math]::Round($cx+$dx/$scale); $sy=[int][Math]::Round($cy+$dy/$scale)
                if ($sx -lt 0 -or $sy -lt 0 -or $sx -ge $source.Width -or $sy -ge $source.Height) { continue }
                $pixel=$source.GetPixel($sx,$sy)
                if ($pixel.A -lt 32) { continue }
                $gray=[int][Math]::Round(($pixel.R+$pixel.G+$pixel.B)/3.0)
                $target.SetPixel($x,$y,[Drawing.Color]::FromArgb($pixel.A,$gray,$gray,$gray))
                $alphaCount++; $outMinX=[Math]::Min($outMinX,$x); $outMinY=[Math]::Min($outMinY,$y)
                $outMaxX=[Math]::Max($outMaxX,$x); $outMaxY=[Math]::Max($outMaxY,$y)
            }
        }
        $out=[IO.Path]::GetFullPath("$AssetRoot/generated/boss_$name.png")
        $target.Save($out,[Drawing.Imaging.ImageFormat]::Png)
        Write-Output "PS144_ASSET_OK name=$name size=$size alpha_pixels=$alphaCount bbox=$outMinX,$outMinY,$($outMaxX+1),$($outMaxY+1)"
    }
    finally { $target.Dispose(); $source.Dispose() }
}
