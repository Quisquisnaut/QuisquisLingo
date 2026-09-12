[CmdletBinding()]
param(
    [switch]$RebuildFlutterApplication
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredRuntimeDlls = @(
    "msvcp140.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

$launcherFileName = "QuisquisLingo.exe"
$requiredDocumentationPlatforms = @(
    "windows",
    "linux",
    "android",
    "macos",
    "ios"
)

function Get-VisualStudioInstallationPaths {
    $installationPaths = @()
    $programFilesX86 = ${env:ProgramFiles(x86)}
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

    @($installationPaths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container) } |
        ForEach-Object { (Resolve-Path -LiteralPath $_).Path } |
        Select-Object -Unique)
}

function Find-CMake {
    $command = Get-Command cmake -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }
    foreach ($installationPath in Get-VisualStudioInstallationPaths) {
        $candidate = Join-Path $installationPath "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    throw "cmake.exe was not found in PATH or an installed Visual Studio instance."
}

function Find-Dumpbin {
    $command = Get-Command dumpbin -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }
    foreach ($installationPath in Get-VisualStudioInstallationPaths) {
        $toolsRoot = Join-Path $installationPath "VC\Tools\MSVC"
        if (-not (Test-Path -LiteralPath $toolsRoot -PathType Container)) {
            continue
        }
        $candidate = Get-ChildItem -LiteralPath $toolsRoot -Directory |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "bin\Hostx64\x64\dumpbin.exe" } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1
        if ($null -ne $candidate) {
            return $candidate
        }
    }
    throw "The x64 dumpbin.exe tool was not found in PATH or Visual Studio."
}

function Get-TreeManifest {
    param(
        [string]$Directory,
        [string[]]$ExcludeRelativePaths = @()
    )

    $resolvedDirectory = (Resolve-Path -LiteralPath $Directory).Path.TrimEnd('\')
    $prefix = "$resolvedDirectory\"
    $excluded = @{}
    foreach ($relativePath in $ExcludeRelativePaths) {
        $excluded[$relativePath.ToLowerInvariant()] = $true
    }

    $manifest = @{}
    foreach ($file in Get-ChildItem -LiteralPath $resolvedDirectory -Recurse -File | Sort-Object FullName) {
        $relativePath = $file.FullName.Substring($prefix.Length)
        if ($excluded.ContainsKey($relativePath.ToLowerInvariant())) {
            continue
        }
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        $manifest[$relativePath] = "$($file.Length)|$hash"
    }
    return $manifest
}

function Assert-MatchingManifests {
    param(
        [hashtable]$Expected,
        [hashtable]$Actual,
        [string]$Description
    )

    $missing = @($Expected.Keys | Where-Object { -not $Actual.ContainsKey($_) } | Sort-Object)
    $unexpected = @($Actual.Keys | Where-Object { -not $Expected.ContainsKey($_) } | Sort-Object)
    $changed = @($Expected.Keys | Where-Object {
        $Actual.ContainsKey($_) -and $Actual[$_] -ne $Expected[$_]
    } | Sort-Object)
    if ($missing.Count -gt 0 -or $unexpected.Count -gt 0 -or $changed.Count -gt 0) {
        throw "$Description failed. Missing: $($missing -join ', '); unexpected: $($unexpected -join ', '); changed: $($changed -join ', ')"
    }
}

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

function Get-PackagingMaterials {
    param([string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "The authoritative matXpack directory is missing: $Directory"
    }

    $allFiles = @(Get-ChildItem -LiteralPath $Directory -File -Force)
    $textAndPdfFiles = @($allFiles | Where-Object {
        $_.Extension -ieq ".txt" -or $_.Extension -ieq ".pdf"
    })
    $documentationFiles = @($textAndPdfFiles | Where-Object {
        $_.BaseName -match '(?i)readme'
    } | Sort-Object Name)
    $ambiguousFiles = @($textAndPdfFiles | Where-Object {
        $_.BaseName -notmatch '(?i)readme'
    })
    if ($ambiguousFiles.Count -gt 0) {
        throw "matXpack contains TXT/PDF files that are not clearly named as QQL README documentation: $($ambiguousFiles.Name -join ', ')"
    }
    if ($documentationFiles.Count -eq 0) {
        throw "matXpack contains no QQL README TXT/PDF documentation files."
    }

    $duplicateNames = @($documentationFiles |
        Group-Object { $_.Name.ToLowerInvariant() } |
        Where-Object Count -gt 1)
    if ($duplicateNames.Count -gt 0) {
        throw "matXpack contains duplicate README filenames: $($duplicateNames.Name -join ', ')"
    }

    foreach ($extension in @(".txt", ".pdf")) {
        foreach ($platform in $requiredDocumentationPlatforms) {
            $matches = @($documentationFiles | Where-Object {
                $_.Extension -ieq $extension -and
                ([regex]::Replace($_.BaseName, '[^A-Za-z0-9]', '').ToLowerInvariant()).Contains($platform)
            })
            if ($matches.Count -lt 1) {
                throw "matXpack must contain at least one $platform README$extension file."
            }
        }
    }

    $infographicFiles = @($allFiles | Where-Object {
        $_.Extension -ieq ".png" -and $_.BaseName -match '(?i)infographic'
    })
    if ($infographicFiles.Count -ne 1) {
        throw "matXpack must contain exactly one authoritative infographic PNG; found $($infographicFiles.Count)."
    }

    return [pscustomobject]@{
        DocumentationFiles = $documentationFiles
        InfographicFile = $infographicFiles[0]
    }
}

function Assert-PackagingMaterials {
    param([string]$Directory)

    foreach ($obsoleteDirectoryName in @("README", "readme")) {
        if (Test-Path -LiteralPath (Join-Path $Directory $obsoleteDirectoryName)) {
            throw "The obsolete multilingual README directory must not be present in the package."
        }
    }

    $actualDocumentationFiles = @(Get-ChildItem -LiteralPath $Directory -File -Force | Where-Object {
        ($_.Extension -ieq ".txt" -or $_.Extension -ieq ".pdf") -and
        $_.BaseName -match '(?i)readme'
    })
    $actualNames = @($actualDocumentationFiles | ForEach-Object Name)
    $missing = @($documentationFileNames | Where-Object { $_ -cnotin $actualNames })
    $unexpected = @($actualNames | Where-Object { $_ -cnotin $documentationFileNames })
    if ($actualDocumentationFiles.Count -ne $documentationFileNames.Count -or
        $missing.Count -gt 0 -or $unexpected.Count -gt 0) {
        throw "Packaged README set differs from matXpack. Missing: $($missing -join ', '); unexpected: $($unexpected -join ', ')"
    }

    foreach ($sourceFile in $documentationSourceFiles) {
        $packagedPath = Join-Path $Directory $sourceFile.Name
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile.FullName).Hash
        $packagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packagedPath).Hash
        if ($sourceFile.Length -ne (Get-Item -LiteralPath $packagedPath).Length -or
            $sourceHash -cne $packagedHash) {
            throw "Packaged README does not match matXpack byte-for-byte: $($sourceFile.Name)"
        }
    }

    $packagedInfographics = @(Get-ChildItem -LiteralPath $Directory -Recurse -File -Force | Where-Object {
        $_.Extension -ieq ".png" -and $_.BaseName -match '(?i)infographic'
    })
    $rootPath = (Resolve-Path -LiteralPath $Directory).Path.TrimEnd('\')
    if ($packagedInfographics.Count -ne 1 -or
        $packagedInfographics[0].Name -cne $infographicFileName -or
        $packagedInfographics[0].DirectoryName.TrimEnd('\') -cne $rootPath) {
        throw "The package must contain exactly the current matXpack infographic at archive root."
    }
    $packagedInfographicHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packagedInfographics[0].FullName).Hash
    if ($packagedInfographics[0].Length -ne $infographicSourceFile.Length -or
        $packagedInfographicHash -cne $infographicSourceHash) {
        throw "The packaged infographic does not match matXpack byte-for-byte."
    }
}

function Assert-ZipHasNoDuplicateEntries {
    param([string]$ZipPath)

    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $duplicates = @($zip.Entries |
            Where-Object { $_.FullName.Length -gt 0 } |
            Group-Object { $_.FullName.Replace('\', '/').TrimEnd('/').ToLowerInvariant() } |
            Where-Object Count -gt 1)
        if ($duplicates.Count -gt 0) {
            throw "ZIP contains duplicate entries: $($duplicates.Name -join ', ')"
        }
    }
    finally {
        $zip.Dispose()
    }
}

function Assert-PackageContents {
    param([string]$Directory)

    $requiredPaths = @(
        $launcherFileName,
        "quisquislingo_app.exe",
        "flutter_windows.dll",
        "native_assets.json",
        "data\icudtl.dat",
        "data\app.so",
        "data\flutter_assets",
        "audioplayers_windows_plugin.dll",
        "screen_retriever_windows_plugin.dll",
        "url_launcher_windows_plugin.dll",
        "window_manager_plugin.dll",
        $infographicFileName
    ) + $requiredRuntimeDlls + $documentationFileNames

    $missing = @($requiredPaths | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Directory $_))
    })
    if ($missing.Count -gt 0) {
        throw "Packaged Windows output is incomplete. Missing: $($missing -join ', ')"
    }
    if (Test-Path -LiteralPath (Join-Path $Directory "flutter_tts_plugin.dll")) {
        throw "Unexpected flutter_tts_plugin.dll found in packaged Windows output."
    }
    Assert-PackagingMaterials -Directory $Directory
}

function Assert-LauncherPeDependencies {
    param(
        [string]$LauncherPath,
        [string]$DumpbinPath
    )

    $dependencyOutput = @(& $DumpbinPath /DEPENDENTS $LauncherPath)
    if ($LASTEXITCODE -ne 0) {
        throw "dumpbin /DEPENDENTS failed for $LauncherPath"
    }
    $dependencies = @($dependencyOutput |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^[A-Za-z0-9_.-]+\.dll$' } |
        ForEach-Object { $_.ToUpperInvariant() } |
        Select-Object -Unique)
    $allowedSystemDependencies = @(
        "COMCTL32.DLL",
        "SHELL32.DLL",
        "KERNEL32.DLL"
    )
    $unexpected = @($dependencies | Where-Object { $_ -notin $allowedSystemDependencies })
    if ($unexpected.Count -gt 0) {
        throw "The bootstrap launcher imports non-approved DLLs: $($unexpected -join ', ')"
    }
    foreach ($forbidden in @(
        "MSVCP140.DLL",
        "VCRUNTIME140.DLL",
        "VCRUNTIME140_1.DLL",
        "UCRTBASE.DLL",
        "FLUTTER_WINDOWS.DLL"
    )) {
        if ($forbidden -in $dependencies) {
            throw "The bootstrap launcher must not import $forbidden"
        }
    }
    if ($dependencies.Count -eq 0) {
        throw "No PE dependencies were parsed for the bootstrap launcher."
    }
    return [pscustomobject]@{
        Output = $dependencyOutput
        Dependencies = $dependencies
    }
}

function Assert-ReleaseStaticRuntime {
    param([string]$ProjectPath)

    $projectText = Get-Content -LiteralPath $ProjectPath -Raw
    $match = [regex]::Match(
        $projectText,
        '(?s)<ItemDefinitionGroup Condition="[^\"]*Release\|x64[^\"]*">(.*?)</ItemDefinitionGroup>')
    if (-not $match.Success) {
        throw "Could not locate the Release|x64 settings in $ProjectPath"
    }
    $releaseSettings = $match.Groups[1].Value
    if ($releaseSettings -notmatch '<RuntimeLibrary>MultiThreaded</RuntimeLibrary>' -or
        $releaseSettings -match '<RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>') {
        throw "Release|x64 does not use the static MultiThreaded runtime in $ProjectPath"
    }
}

$projectRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$packagingMaterialsDirectory = Join-Path $projectRoot "matXpack"
$packagingMaterials = Get-PackagingMaterials -Directory $packagingMaterialsDirectory
$documentationSourceFiles = @($packagingMaterials.DocumentationFiles)
$documentationFileNames = @($documentationSourceFiles | ForEach-Object Name)
$infographicSourceFile = $packagingMaterials.InfographicFile
$infographicSource = $infographicSourceFile.FullName
$infographicFileName = $infographicSourceFile.Name
$infographicSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $infographicSource).Hash
$versionMatch = Select-String -Path (Join-Path $projectRoot "pubspec.yaml") -Pattern '^version:\s*([^\s]+)\+(\d+)\s*$'
if ($null -eq $versionMatch) {
    throw "Could not read the numeric Flutter build number from pubspec.yaml."
}
$qqlVersion = "$($versionMatch.Matches[0].Groups[1].Value)+$($versionMatch.Matches[0].Groups[2].Value)"
$buildNumber = $versionMatch.Matches[0].Groups[2].Value
$packageName = "quisquislingo_windows_alpha_${buildNumber}"
$releaseDirectory = Join-Path $projectRoot "build\windows\x64\runner\Release"
$nativeBuildDirectory = Join-Path $projectRoot "build\windows\x64"

if ($RebuildFlutterApplication) {
    Push-Location $projectRoot
    try {
        & flutter build windows --release --no-pub
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Windows release build failed."
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Windows Release directory was not found: $releaseDirectory. Build and validate the frozen Flutter application first."
}
if (-not (Test-Path -LiteralPath $nativeBuildDirectory -PathType Container)) {
    throw "The configured native Windows build directory was not found: $nativeBuildDirectory"
}

$childExecutable = Join-Path $releaseDirectory "quisquislingo_app.exe"
if (-not (Test-Path -LiteralPath $childExecutable -PathType Leaf)) {
    throw "The frozen internal Flutter executable is missing: $childExecutable"
}
$childProductVersion = (Get-Item -LiteralPath $childExecutable).VersionInfo.ProductVersion
if ($childProductVersion -ne $qqlVersion) {
    throw "The internal Flutter executable reports $childProductVersion instead of pubspec version $qqlVersion."
}

# Freeze every existing QQL/Flutter package byte before compiling the standalone
# launcher. QuisquisLingo.exe is the only native output excluded from this map.
$frozenApplicationManifest = Get-TreeManifest `
    -Directory $releaseDirectory `
    -ExcludeRelativePaths @($launcherFileName)
$frozenApplicationBytes = 0L
foreach ($value in $frozenApplicationManifest.Values) {
    $frozenApplicationBytes += [long]($value.Split('|')[0])
}

$cmakePath = Find-CMake
$dumpbinPath = Find-Dumpbin
$launcherProject = Join-Path $nativeBuildDirectory "launcher\qql_bootstrap_launcher.vcxproj"
$launcherTestsProject = Join-Path $nativeBuildDirectory "launcher\qql_bootstrap_launcher_tests.vcxproj"
$packageTestsProject = Join-Path $nativeBuildDirectory "launcher\qql_bootstrap_package_tests.vcxproj"
$childProbeProject = Join-Path $nativeBuildDirectory "launcher\qql_bootstrap_child_probe.vcxproj"

& $cmakePath --build $nativeBuildDirectory --config Release --target `
    qql_bootstrap_launcher_tests qql_bootstrap_package_tests
if ($LASTEXITCODE -ne 0) {
    throw "Native bootstrap launcher/test build failed."
}

foreach ($project in @(
    $launcherProject,
    $launcherTestsProject,
    $packageTestsProject,
    $childProbeProject
)) {
    Assert-ReleaseStaticRuntime -ProjectPath $project
}

$launcherOutput = Join-Path $nativeBuildDirectory "launcher\Release\$launcherFileName"
$launcherTests = Join-Path $nativeBuildDirectory "launcher\Release\qql_bootstrap_launcher_tests.exe"
$packageTests = Join-Path $nativeBuildDirectory "launcher\Release\qql_bootstrap_package_tests.exe"
$childProbe = Join-Path $nativeBuildDirectory "launcher\Release\qql_bootstrap_child_probe.exe"
foreach ($nativeOutput in @($launcherOutput, $launcherTests, $packageTests, $childProbe)) {
    if (-not (Test-Path -LiteralPath $nativeOutput -PathType Leaf)) {
        throw "Expected native output is missing: $nativeOutput"
    }
}

& $launcherTests
if ($LASTEXITCODE -ne 0) {
    throw "Bootstrap launcher unit tests failed."
}
& $packageTests $launcherOutput $childProbe
if ($LASTEXITCODE -ne 0) {
    throw "Packaged-launcher integration tests failed."
}

$sourcePeResult = Assert-LauncherPeDependencies `
    -LauncherPath $launcherOutput `
    -DumpbinPath $dumpbinPath

$applicationManifestAfterNativeBuild = Get-TreeManifest `
    -Directory $releaseDirectory `
    -ExcludeRelativePaths @($launcherFileName)
Assert-MatchingManifests `
    -Expected $frozenApplicationManifest `
    -Actual $applicationManifestAfterNativeBuild `
    -Description "Frozen QQL $qqlVersion application preservation"

$runtimeSource = Find-VcRuntimeDirectory -RequiredDlls $requiredRuntimeDlls
foreach ($packagingMaterial in @($documentationSourceFiles) + @($infographicSourceFile)) {
    if (Test-Path -LiteralPath (Join-Path $releaseDirectory $packagingMaterial.Name)) {
        throw "Packaging material would overwrite a generated Windows runtime file: $($packagingMaterial.Name)"
    }
}
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
Copy-Item -LiteralPath $launcherOutput -Destination (Join-Path $stagingDirectory $launcherFileName) -Force
foreach ($documentationSourceFile in $documentationSourceFiles) {
    Copy-Item -LiteralPath $documentationSourceFile.FullName -Destination (Join-Path $stagingDirectory $documentationSourceFile.Name)
}
Copy-Item -LiteralPath $infographicSource -Destination (Join-Path $stagingDirectory $infographicFileName) -Force
foreach ($dll in $requiredRuntimeDlls) {
    Copy-Item -LiteralPath (Join-Path $runtimeSource $dll) -Destination (Join-Path $stagingDirectory $dll) -Force
}

Assert-PackageContents -Directory $stagingDirectory
$packagingOnlyPaths = @(
    $launcherFileName,
    $infographicFileName
) + $requiredRuntimeDlls + $documentationFileNames
$stagedApplicationManifest = Get-TreeManifest `
    -Directory $stagingDirectory `
    -ExcludeRelativePaths $packagingOnlyPaths
Assert-MatchingManifests `
    -Expected $frozenApplicationManifest `
    -Actual $stagedApplicationManifest `
    -Description "Staged frozen QQL $qqlVersion application"

$expectedPackageManifest = @{}
foreach ($entry in $frozenApplicationManifest.GetEnumerator()) {
    $expectedPackageManifest[$entry.Key] = $entry.Value
}
foreach ($extra in @(
    @{ RelativePath = $launcherFileName; Source = $launcherOutput },
    @{ RelativePath = $infographicFileName; Source = $infographicSource }
)) {
    $item = Get-Item -LiteralPath $extra.Source
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $extra.Source).Hash
    $expectedPackageManifest[$extra.RelativePath] = "$($item.Length)|$hash"
}
foreach ($documentationSourceFile in $documentationSourceFiles) {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $documentationSourceFile.FullName).Hash
    $expectedPackageManifest[$documentationSourceFile.Name] = "$($documentationSourceFile.Length)|$hash"
}
foreach ($dll in $requiredRuntimeDlls) {
    $runtimePath = Join-Path $runtimeSource $dll
    $item = Get-Item -LiteralPath $runtimePath
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $runtimePath).Hash
    $expectedPackageManifest[$dll] = "$($item.Length)|$hash"
}
$stagedPackageManifest = Get-TreeManifest -Directory $stagingDirectory
Assert-MatchingManifests `
    -Expected $expectedPackageManifest `
    -Actual $stagedPackageManifest `
    -Description "Staged package file set and SHA-256 content"

$stagedPeResult = Assert-LauncherPeDependencies `
    -LauncherPath (Join-Path $stagingDirectory $launcherFileName) `
    -DumpbinPath $dumpbinPath
Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $zipPath -CompressionLevel Optimal
Assert-ZipHasNoDuplicateEntries -ZipPath $zipPath

try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $zipValidationDirectory
    Assert-PackageContents -Directory $zipValidationDirectory
    $zipManifest = Get-TreeManifest -Directory $zipValidationDirectory
    Assert-MatchingManifests `
        -Expected $expectedPackageManifest `
        -Actual $zipManifest `
        -Description "Extracted ZIP file set and SHA-256 content"
    $zipPeResult = Assert-LauncherPeDependencies `
        -LauncherPath (Join-Path $zipValidationDirectory $launcherFileName) `
        -DumpbinPath $dumpbinPath
}
finally {
    if (Test-Path -LiteralPath $zipValidationDirectory) {
        Remove-Item -LiteralPath $zipValidationDirectory -Recurse -Force
    }
}

Write-Host "QuisquisLingo Windows standalone release package prepared."
Write-Host "QQL application version: $qqlVersion (unchanged)"
Write-Host "Frozen QQL files: $($frozenApplicationManifest.Count) ($frozenApplicationBytes bytes)"
Write-Host "Native launcher tests: passed"
Write-Host "Packaged-launcher integration tests: passed"
Write-Host "Launcher PE dependencies: $($sourcePeResult.Dependencies -join ', ')"
Write-Host "Staged launcher PE dependencies: $($stagedPeResult.Dependencies -join ', ')"
Write-Host "ZIP launcher PE dependencies: $($zipPeResult.Dependencies -join ', ')"
Write-Host "PE inspection tool: $dumpbinPath /DEPENDENTS"
Write-Host "VC runtime source: $runtimeSource"
Write-Host "Staging directory: $stagingDirectory"
Write-Host "ZIP package: $zipPath"
Write-Host "Normal packaged entry point: $launcherFileName"
Write-Host "Distribute or test the complete staged directory or ZIP contents, not either EXE alone."
