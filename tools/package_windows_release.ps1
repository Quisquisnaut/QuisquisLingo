[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredRuntimeDlls = @(
    "msvcp140.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

function Get-VisualStudioRedistDirectories {
    param([string]$InstallationPath)

    $redistRoot = Join-Path $InstallationPath "VC\Redist\MSVC"
    if (-not (Test-Path -LiteralPath $redistRoot -PathType Container)) {
        return
    }

    $versions = Get-ChildItem -LiteralPath $redistRoot -Directory | Sort-Object Name -Descending
    foreach ($version in $versions) {
        $x64Root = Join-Path $version.FullName "x64"
        if (Test-Path -LiteralPath $x64Root -PathType Container) {
            Get-ChildItem -LiteralPath $x64Root -Directory -Filter "Microsoft.VC*.CRT" |
                Sort-Object Name -Descending |
                ForEach-Object { $_.FullName }
        }
    }
}

function Find-VcRuntimeDirectory {
    param([string[]]$RequiredDlls)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:VCToolsRedistDir)) {
        $candidates += $env:VCToolsRedistDir
        $environmentX64 = Join-Path $env:VCToolsRedistDir "x64"
        if (Test-Path -LiteralPath $environmentX64 -PathType Container) {
            $candidates += Get-ChildItem -LiteralPath $environmentX64 -Directory -Filter "Microsoft.VC*.CRT" |
                Sort-Object Name -Descending |
                ForEach-Object { $_.FullName }
        }
    }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    $installationPaths = @()
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $vswhere = Join-Path $programFilesX86 "Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
            $json = & $vswhere -all -products "*" -format json
            if ($LASTEXITCODE -ne 0) {
                throw "vswhere failed while locating installed Visual Studio instances."
            }
            $instances = @($json | ConvertFrom-Json) | Sort-Object installationVersion -Descending
            $installationPaths += $instances | ForEach-Object { $_.installationPath }
        }
    }

    $visualStudioRoots = @()
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $visualStudioRoots += Join-Path $env:ProgramFiles "Microsoft Visual Studio"
    }
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $visualStudioRoots += Join-Path $programFilesX86 "Microsoft Visual Studio"
    }
    foreach ($visualStudioRoot in $visualStudioRoots) {
        if (-not (Test-Path -LiteralPath $visualStudioRoot -PathType Container)) {
            continue
        }
        foreach ($productLine in Get-ChildItem -LiteralPath $visualStudioRoot -Directory) {
            $installationPaths += Get-ChildItem -LiteralPath $productLine.FullName -Directory |
                ForEach-Object { $_.FullName }
        }
    }

    foreach ($installationPath in $installationPaths | Select-Object -Unique) {
        $candidates += Get-VisualStudioRedistDirectories -InstallationPath $installationPath
    }

    $resolvedCandidates = @($candidates |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container) } |
        ForEach-Object { (Resolve-Path -LiteralPath $_).Path } |
        Select-Object -Unique)

    $incomplete = @()
    foreach ($candidate in $resolvedCandidates) {
        $missing = @($RequiredDlls | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $candidate $_) -PathType Leaf)
        })
        if ($missing.Count -eq 0) {
            return $candidate
        }
        $incomplete += "$candidate (missing: $($missing -join ', '))"
    }

    if ($incomplete.Count -gt 0) {
        throw "No complete x64 VC runtime directory was found. Examined: $($incomplete -join '; ')"
    }
    throw "No Visual Studio x64 VC Redist CRT directory was found. Missing required DLLs: $($RequiredDlls -join ', ')"
}

function Assert-PackageContents {
    param([string]$Directory)

    $requiredPaths = @(
        "quisquislingo_app.exe",
        "flutter_windows.dll",
        "data\icudtl.dat",
        "data\app.so",
        "data\flutter_assets",
        "audioplayers_windows_plugin.dll",
        "screen_retriever_windows_plugin.dll",
        "url_launcher_windows_plugin.dll",
        "window_manager_plugin.dll"
    ) + $requiredRuntimeDlls

    $missing = @($requiredPaths | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Directory $_))
    })
    if ($missing.Count -gt 0) {
        throw "Packaged Windows output is incomplete. Missing: $($missing -join ', ')"
    }
    if (Test-Path -LiteralPath (Join-Path $Directory "flutter_tts_plugin.dll")) {
        throw "Unexpected flutter_tts_plugin.dll found in packaged Windows output."
    }
}

function Assert-MatchingFiles {
    param(
        [string]$ExpectedDirectory,
        [string]$ActualDirectory
    )

    $expectedPrefix = $ExpectedDirectory.TrimEnd('\') + '\'
    $mismatches = @()
    foreach ($file in Get-ChildItem -LiteralPath $ExpectedDirectory -Recurse -File) {
        $relativePath = $file.FullName.Substring($expectedPrefix.Length)
        $actualPath = Join-Path $ActualDirectory $relativePath
        if (-not (Test-Path -LiteralPath $actualPath -PathType Leaf)) {
            $mismatches += $relativePath
            continue
        }
        if ((Get-Item -LiteralPath $actualPath).Length -ne $file.Length) {
            $mismatches += $relativePath
        }
    }
    if ($mismatches.Count -gt 0) {
        throw "ZIP validation failed for: $($mismatches -join ', ')"
    }
}

$projectRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$versionMatch = Select-String -Path (Join-Path $projectRoot "pubspec.yaml") -Pattern '^version:\s*[^+]+\+(\d+)\s*$'
if ($null -eq $versionMatch) {
    throw "Could not read the numeric Flutter build number from pubspec.yaml."
}
$buildNumber = $versionMatch.Matches[0].Groups[1].Value
$packageName = "quisquislingo_alpha_${buildNumber}_dev_windows_x64"

Push-Location $projectRoot
try {
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Windows release build failed."
    }
}
finally {
    Pop-Location
}

$releaseDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Windows Release directory was not found: $releaseDirectory"
}

$runtimeSource = Find-VcRuntimeDirectory -RequiredDlls $requiredRuntimeDlls
$packagesRoot = Join-Path $projectRoot "build\packages"
$stagingDirectory = Join-Path $packagesRoot $packageName
$zipPath = Join-Path $packagesRoot "$packageName.zip"
$zipValidationDirectory = Join-Path $packagesRoot ".${packageName}_zip_validation"

New-Item -ItemType Directory -Path $packagesRoot -Force | Out-Null
$resolvedPackagesRoot = (Resolve-Path -LiteralPath $packagesRoot).Path.TrimEnd('\')
foreach ($generatedPath in @($stagingDirectory, $zipPath, $zipValidationDirectory)) {
    $resolvedGeneratedPath = [System.IO.Path]::GetFullPath($generatedPath)
    if (-not $resolvedGeneratedPath.StartsWith("$resolvedPackagesRoot\", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to replace a generated path outside $resolvedPackagesRoot"
    }
}

foreach ($generatedPath in @($stagingDirectory, $zipPath, $zipValidationDirectory)) {
    if (Test-Path -LiteralPath $generatedPath) {
        Remove-Item -LiteralPath $generatedPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Path $stagingDirectory | Out-Null

Get-ChildItem -LiteralPath $releaseDirectory -Force | Copy-Item -Destination $stagingDirectory -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot "readme_windows.txt") -Destination (Join-Path $stagingDirectory "readme.txt") -Force
foreach ($dll in $requiredRuntimeDlls) {
    Copy-Item -LiteralPath (Join-Path $runtimeSource $dll) -Destination (Join-Path $stagingDirectory $dll) -Force
}

Assert-PackageContents -Directory $stagingDirectory
Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $zipPath -CompressionLevel Optimal

try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $zipValidationDirectory
    Assert-PackageContents -Directory $zipValidationDirectory
    Assert-MatchingFiles -ExpectedDirectory $stagingDirectory -ActualDirectory $zipValidationDirectory
}
finally {
    if (Test-Path -LiteralPath $zipValidationDirectory) {
        Remove-Item -LiteralPath $zipValidationDirectory -Recurse -Force
    }
}

Write-Host "QuisquisLingo Windows development package prepared."
Write-Host "VC runtime source: $runtimeSource"
Write-Host "Staging directory: $stagingDirectory"
Write-Host "ZIP package: $zipPath"
Write-Host "Distribute or test the complete staged directory or ZIP contents, not the EXE alone."
