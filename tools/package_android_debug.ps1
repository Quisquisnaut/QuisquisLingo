[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$materialsDirectory = Join-Path $projectRoot "matXpack"
if (-not (Test-Path -LiteralPath $materialsDirectory -PathType Container)) {
    throw "The authoritative matXpack directory is missing: $materialsDirectory"
}

$materialFiles = @(
    Get-ChildItem -LiteralPath $materialsDirectory -File -Force |
        Where-Object { $_.Extension -in ".pdf", ".png", ".txt" } |
        Sort-Object Name
)
if ($materialFiles.Count -ne 11) {
    throw "matXpack must contain the 11 approved PDF, PNG and TXT package files."
}

$versionMatch = Select-String -Path (Join-Path $projectRoot "pubspec.yaml") -Pattern '^version:\s*([^\s]+)\+(\d+)\s*$'
if ($null -eq $versionMatch) {
    throw "Could not read the numeric Flutter build number from pubspec.yaml."
}
$buildNumber = $versionMatch.Matches[0].Groups[2].Value
$packageName = "quisquislingo_android_debug_beta_${buildNumber}"
$packagesRoot = Join-Path $projectRoot "build\packages"
$stagingDirectory = Join-Path $packagesRoot $packageName
$zipPath = Join-Path $packagesRoot "$packageName.zip"
$apkSource = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
$apkName = "$packageName.apk"

Push-Location $projectRoot
try {
    & flutter build apk --debug --no-pub
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Android debug APK build failed."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $apkSource -PathType Leaf)) {
    throw "Android debug APK was not produced: $apkSource"
}

New-Item -ItemType Directory -Path $packagesRoot -Force | Out-Null
foreach ($generatedPath in @($stagingDirectory, $zipPath)) {
    if (Test-Path -LiteralPath $generatedPath) {
        Remove-Item -LiteralPath $generatedPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Path $stagingDirectory | Out-Null

$apkDestination = Join-Path $stagingDirectory $apkName
Copy-Item -LiteralPath $apkSource -Destination $apkDestination
$packagedFiles = @(
    [pscustomobject]@{
        Source = $apkSource
        Destination = $apkDestination
    }
)
foreach ($material in $materialFiles) {
    $destination = Join-Path $stagingDirectory $material.Name
    Copy-Item -LiteralPath $material.FullName -Destination $destination
    $packagedFiles += [pscustomobject]@{
        Source = $material.FullName
        Destination = $destination
    }
}

foreach ($packageFile in $packagedFiles) {
    if (-not (Test-Path -LiteralPath $packageFile.Destination -PathType Leaf)) {
        throw "Required package file is missing: $(Split-Path -Leaf $packageFile.Destination)"
    }
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packageFile.Source).Hash
    $destinationHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packageFile.Destination).Hash
    if ($sourceHash -cne $destinationHash) {
        throw "Packaged file differs from its source: $(Split-Path -Leaf $packageFile.Destination)"
    }
}

Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "QuisquisLingo Android debug package prepared: $zipPath"
Write-Host "APK: $apkDestination"
