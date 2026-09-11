[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$InputPath,

	[Parameter(Mandatory = $true)]
	[string]$OutputPath,

	[ValidateRange(48, 320)]
	[int]$BitrateKbps = 112,

	[ValidateSet(32000, 44100, 48000)]
	[int]$SampleRate = 44100,

	[ValidateRange(1, 2)]
	[int]$Channels = 2,

	[ValidateRange(0, 1000)]
	[int]$MaxDurationDriftMilliseconds = 100,

	[switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-AudioProbe {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.CommandInfo]$Ffprobe
	)

	$probeJson = (& $Ffprobe.Source `
		-v error `
		-select_streams a:0 `
		-show_entries "format=duration,size,bit_rate:stream=codec_name,sample_rate,channels,bit_rate" `
		-of json `
		-- $Path) | Out-String
	if ($LASTEXITCODE -ne 0) {
		throw "ffprobe non riesce a leggere la traccia: $Path"
	}

	$probe = $probeJson | ConvertFrom-Json
	if (@($probe.streams).Count -ne 1) {
		throw "La traccia deve contenere esattamente uno stream audio leggibile: $Path"
	}

	return $probe
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if ($null -eq $ffmpeg -or $null -eq $ffprobe) {
	throw "ffmpeg e ffprobe devono essere disponibili nel PATH."
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
if ([System.StringComparer]::OrdinalIgnoreCase.Equals($resolvedInput, $resolvedOutput)) {
	throw "Input e output devono essere file distinti: il master non viene sovrascritto."
}
if ([System.IO.Path]::GetExtension($resolvedOutput) -ne ".ogg") {
	throw "Il derivato runtime deve usare l'estensione .ogg: $resolvedOutput"
}
if ([System.IO.File]::Exists($resolvedOutput) -and -not $Force) {
	throw "L'output esiste già. Passare -Force per rigenerarlo: $resolvedOutput"
}

$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($outputDirectory)) {
	[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$inputProbe = Get-AudioProbe -Path $resolvedInput -Ffprobe $ffprobe
$inputDuration = [double]$inputProbe.format.duration
$inputFile = Get-Item -LiteralPath $resolvedInput
$temporaryOutput = Join-Path $outputDirectory (
	".{0}.{1}.tmp.ogg" -f
	[System.IO.Path]::GetFileNameWithoutExtension($resolvedOutput),
	[guid]::NewGuid().ToString("N")
)

try {
	$ffmpegOutput = (& $ffmpeg.Source `
		-nostdin `
		-hide_banner `
		-loglevel error `
		-i $resolvedInput `
		-map "0:a:0" `
		-vn `
		-map_metadata -1 `
		-map_chapters -1 `
		-fflags +bitexact `
		-c:a libvorbis `
		-b:a ("{0}k" -f $BitrateKbps) `
		-ar $SampleRate `
		-ac $Channels `
		-y `
		$temporaryOutput) 2>&1
	if ($LASTEXITCODE -ne 0) {
		throw "ffmpeg ha fallito: $($ffmpegOutput -join [Environment]::NewLine)"
	}

	$outputProbe = Get-AudioProbe -Path $temporaryOutput -Ffprobe $ffprobe
	if ($outputProbe.streams[0].codec_name -ne "vorbis") {
		throw "Codec inatteso nel derivato: $($outputProbe.streams[0].codec_name)"
	}
	if ([int]$outputProbe.streams[0].sample_rate -ne $SampleRate) {
		throw "Sample rate inatteso nel derivato: $($outputProbe.streams[0].sample_rate)"
	}
	if ([int]$outputProbe.streams[0].channels -ne $Channels) {
		throw "Numero di canali inatteso nel derivato: $($outputProbe.streams[0].channels)"
	}

	$outputDuration = [double]$outputProbe.format.duration
	$durationDriftMilliseconds = [Math]::Abs($outputDuration - $inputDuration) * 1000.0
	if ($durationDriftMilliseconds -gt $MaxDurationDriftMilliseconds) {
		throw (
			"Durata incoerente: deriva di {0:N3} ms, massimo {1} ms." -f
			$durationDriftMilliseconds,
			$MaxDurationDriftMilliseconds
		)
	}

	$temporaryFile = Get-Item -LiteralPath $temporaryOutput
	if ($temporaryFile.Length -ge $inputFile.Length) {
		throw (
			"Il derivato non è più piccolo del master: input={0}, output={1}." -f
			$inputFile.Length,
			$temporaryFile.Length
		)
	}

	if ([System.IO.File]::Exists($resolvedOutput)) {
		[System.IO.File]::Delete($resolvedOutput)
	}
	[System.IO.File]::Move($temporaryOutput, $resolvedOutput)
}
finally {
	if ([System.IO.File]::Exists($temporaryOutput)) {
		[System.IO.File]::Delete($temporaryOutput)
	}
}

$outputFile = Get-Item -LiteralPath $resolvedOutput
$inputHash = Get-FileHash -LiteralPath $resolvedInput -Algorithm SHA256
$outputHash = Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256
$reductionPercent = 100.0 * (1.0 - ($outputFile.Length / [double]$inputFile.Length))

Write-Output (
	"AUDIO_MUSIC_DERIVATIVE_OK input={0} output={1} bitrate_kbps={2} sample_rate={3} channels={4} duration_seconds={5:N3} duration_drift_ms={6:N3} input_bytes={7} output_bytes={8} reduction_pct={9:N2} input_sha256={10} output_sha256={11}" -f
	$resolvedInput,
	$resolvedOutput,
	$BitrateKbps,
	$SampleRate,
	$Channels,
	[double]$outputProbe.format.duration,
	$durationDriftMilliseconds,
	$inputFile.Length,
	$outputFile.Length,
	$reductionPercent,
	$inputHash.Hash,
	$outputHash.Hash
)
