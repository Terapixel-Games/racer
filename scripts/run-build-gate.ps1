param(
	[string]$GodotBin = "godot",
	[string]$WebExportPreset = "Web",
	[string]$WebExportPath = "build/web/index.html",
	[int64]$MaxWebPckBytes = 500000000,
	[string]$VisualRegressionRacers = "Rexx,Moko"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ExportPresetsPath = Join-Path $ProjectRoot "export_presets.cfg"

function Resolve-GodotCommand([string]$RequestedBin) {
	$command = Get-Command $RequestedBin -ErrorAction Stop
	$resolved = $command.Source
	if ([System.IO.Path]::GetFileName($resolved).ToLowerInvariant() -eq "godot.exe") {
		$consoleBin = Join-Path (Split-Path $resolved -Parent) "godot_console.exe"
		if (Test-Path $consoleBin) {
			return $consoleBin
		}
	}
	return $resolved
}

function Invoke-Native([string]$Description, [string]$Command, [string[]]$Arguments) {
	Write-Host $Description
	$previousErrorActionPreference = $ErrorActionPreference
	$nativePreferenceWasPresent = $null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue)
	$previousNativePreference = $false
	if ($nativePreferenceWasPresent) {
		$previousNativePreference = $PSNativeCommandUseErrorActionPreference
	}
	try {
		$ErrorActionPreference = "Continue"
		if ($nativePreferenceWasPresent) {
			$PSNativeCommandUseErrorActionPreference = $false
		}
		$output = & $Command @Arguments 2>&1
		$exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
	}
	finally {
		$ErrorActionPreference = $previousErrorActionPreference
		if ($nativePreferenceWasPresent) {
			$PSNativeCommandUseErrorActionPreference = $previousNativePreference
		}
	}
	$outputText = ($output | Out-String).Trim()
	if ($outputText -ne "") {
		Write-Host $outputText
	}
	if ($exitCode -ne 0) {
		throw "$Description failed with exit code $exitCode"
	}
	return $outputText
}

function Assert-Condition([bool]$Condition, [string]$Message) {
	if (-not $Condition) {
		throw $Message
	}
}

function Get-JsonObjectFromOutput([string]$OutputText) {
	$start = $OutputText.IndexOf("{")
	$end = $OutputText.LastIndexOf("}")
	if ($start -lt 0 -or $end -le $start) {
		throw "Package size audit did not print a JSON object."
	}
	$jsonText = $OutputText.Substring($start, $end - $start + 1)
	return $jsonText | ConvertFrom-Json
}

function Get-ChangedFiles() {
	$files = New-Object System.Collections.Generic.HashSet[string]
	$git = Get-Command git -ErrorAction SilentlyContinue
	if ($null -eq $git) {
		return @()
	}
	$diffRanges = @()
	if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF)) {
		$diffRanges += "origin/$($env:GITHUB_BASE_REF)...HEAD"
	}
	$diffRanges += "HEAD~1..HEAD"
	foreach ($range in $diffRanges) {
		try {
			$rangeFiles = & $git.Source diff --name-only $range 2>$null
			foreach ($file in $rangeFiles) {
				if (-not [string]::IsNullOrWhiteSpace($file)) {
					[void]$files.Add(($file -replace "\\", "/"))
				}
			}
		}
		catch {
		}
	}
	try {
		$statusFiles = & $git.Source status --short
		foreach ($line in $statusFiles) {
			if ($line.Length -gt 3) {
				[void]$files.Add(($line.Substring(3).Trim() -replace "\\", "/"))
			}
		}
	}
	catch {
	}
	return @($files)
}

function Test-RacerVisualInputChanged([string[]]$ChangedFiles) {
	foreach ($file in $ChangedFiles) {
		if ($file.StartsWith("assets/optimized/racers/")) {
			return $true
		}
		if ($file -eq "scripts/logic/RacerRoster.gd") {
			return $true
		}
		if ($file -eq "scripts/logic/RacerVisualRegression.gd") {
			return $true
		}
		if ($file -eq "tools/capture/RacerVisualRegressionCapture.gd") {
			return $true
		}
	}
	return $false
}

$ResolvedGodotBin = Resolve-GodotCommand $GodotBin
Write-Host "Using Godot: $ResolvedGodotBin"

Assert-Condition (Test-Path $ExportPresetsPath) "export_presets.cfg is required for the build gate."
$exportPresets = Get-Content -Path $ExportPresetsPath -Raw
Assert-Condition ($exportPresets.Contains('name="Web"')) "Web export preset is missing."
Assert-Condition ($exportPresets.Contains('export_filter="resources"')) "Web export must keep the explicit resource allowlist."
Assert-Condition (-not $exportPresets.Contains("assets/source/meshy/2026-04-27-character-track-batch")) "Web export allowlist includes legacy Meshy racer source assets."
Assert-Condition ($exportPresets.Contains("assets/source/*,assets/source/**")) "Android export must exclude assets/source/**."
Assert-Condition (-not ($exportPresets -match "_lod[12]_Image_0\.jpg")) "LOD1/LOD2 atlas source images should not be allowlisted; LODs reuse the LOD0 atlas."

Invoke-Native "Importing project for build gate..." $ResolvedGodotBin @("--headless", "--recovery-mode", "--path", $ProjectRoot, "--import", "--quit")
& (Join-Path $PSScriptRoot "run-tests.ps1") -Suite all -GodotBin $ResolvedGodotBin
if ($LASTEXITCODE -ne 0) {
	throw "Unit/UAT test gate failed."
}

$webExportAbsolutePath = Join-Path $ProjectRoot $WebExportPath
$webExportDirectory = Split-Path $webExportAbsolutePath -Parent
New-Item -ItemType Directory -Path $webExportDirectory -Force | Out-Null
Invoke-Native "Exporting fresh Web build..." $ResolvedGodotBin @("--headless", "--recovery-mode", "--path", $ProjectRoot, "--export-release", $WebExportPreset, $webExportAbsolutePath)

$auditOutput = Invoke-Native "Running package size audit..." $ResolvedGodotBin @("--headless", "--path", $ProjectRoot, "--script", "res://tools/package_size_audit.gd")
$audit = Get-JsonObjectFromOutput $auditOutput
$webPckBytes = [int64]$audit.web_pck_bytes
Assert-Condition ($webPckBytes -gt 0) "PackageSizeAudit did not find build/web/index.pck."
Assert-Condition ($webPckBytes -le $MaxWebPckBytes) "Web index.pck is $webPckBytes bytes, above the gate budget of $MaxWebPckBytes bytes."
Assert-Condition ([int64]$audit.optimized_racer_lod0_glb_bytes -gt 0) "PackageSizeAudit did not find optimized LOD0 racer GLBs."
Assert-Condition ([int64]$audit.optimized_racer_lod_glb_bytes -gt 0) "PackageSizeAudit did not find staged racer LOD GLBs."
Assert-Condition ([int64]$audit.optimized_racer_lod_atlas_source_bytes -eq 0) "Staged LOD atlas source images are present; LOD GLBs should reuse LOD0 atlases."

$changedFiles = Get-ChangedFiles
if (Test-RacerVisualInputChanged $changedFiles) {
	$visualArgs = @(
		"--headless",
		"--path",
		$ProjectRoot,
		"--script",
		"res://tools/capture/RacerVisualRegressionCapture.gd",
		"--",
		"--manifest_only=true",
		"--phase=ci",
		"--output_dir=reports/racer_visual_regression/ci",
		"--racers=$VisualRegressionRacers"
	)
	Invoke-Native "Running racer visual-regression manifest gate..." $ResolvedGodotBin $visualArgs
}
else {
	Write-Host "No racer visual inputs changed; visual-regression manifest gate not required for this diff."
}

Write-Host "Build gate passed."
Write-Host ("Web index.pck bytes: {0}" -f $webPckBytes)
Write-Host ("Web build total bytes: {0}" -f ([int64]$audit.web_build_total_bytes))
Write-Host ("Runtime racer GLB bytes: {0}" -f ([int64]$audit.optimized_racer_runtime_glb_bytes))
