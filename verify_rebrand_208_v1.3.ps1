param(
    [switch]$ShowFullDiff
)

# QuisquisLingo 2.0.8+208 Rebranding Verification
# Script version: 1.3.0
#
# Purpose:
#   Verify that the active QuisquisLingo working tree no longer contains
#   LingoGrow branding, while ignoring generated/ignored build artifacts
#   and deleted paths that remain visible in the Git index until staging.
#
# Important:
#   - This script is READ-ONLY.
#   - It does not stage, commit, restore, rename, delete, build, analyze, or test.
#   - It intentionally does NOT run flutter analyze or flutter test.
#   - All Git diff commands run with --no-pager, so the script cannot pause in a Git pager.
#
# Run from the repository root:
#
#   powershell -ExecutionPolicy Bypass -File .\verify_rebrand_208_v1.3.ps1
#
# To print the complete Git diff too:
#
#   powershell -ExecutionPolicy Bypass -File .\verify_rebrand_208_v1.3.ps1 -ShowFullDiff
#
# Interpretation:
#   PASS   = expected state.
#   REVIEW = something needs inspection before accepting build 208.
#   INFO   = informational only.
#
# Historical/context exception:
#   AGENTS.md and CHANGELOG.md may legitimately mention the former name when
#   documenting old releases or the clean-cut rebrand decision. Those matches
#   are listed separately and do not count as active-branding failures.
#
# Rebranding verifier scripts necessarily contain the word "LingoGrow" and are excluded
# from the content/path branding checks. This includes older verifier versions left untracked.

$ErrorActionPreference = 'Stop'

$ExpectedVersion = '2.0.8+208'
$ExpectedOrigin = 'https://github.com/Quisquisnaut/QuisquisLingo.git'
$VerifierName = Split-Path -Leaf $PSCommandPath
$VerifierPattern = '^verify_rebrand_208(?:_v[0-9.]+)?\.ps1$'

$HistoricalContextFiles = @(
    'AGENTS.md',
    'CHANGELOG.md'
)

$BinaryExtensions = @(
    '.a', '.avi', '.bin', '.bmp', '.db', '.dll', '.dylib', '.exe',
    '.flac', '.gif', '.ico', '.jpeg', '.jpg', '.lib', '.mov', '.mp3',
    '.mp4', '.ogg', '.otf', '.pdf', '.pdb', '.png', '.so', '.sqlite',
    '.ttf', '.wav', '.webp', '.zip'
)

$ReviewCount = 0

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host '============================================================'
    Write-Host $Title
    Write-Host '============================================================'
}

function Write-Pass {
    param([string]$Text)
    Write-Host "[PASS] $Text"
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text"
}

function Write-Review {
    param([string]$Text)
    $script:ReviewCount++
    Write-Host "[REVIEW] $Text"
}

function Normalize-GitPath {
    param([string]$Path)
    return ($Path -replace '\\', '/').TrimStart('./')
}

function Is-HistoricalContextFile {
    param([string]$Path)
    $normalized = Normalize-GitPath $Path
    return $HistoricalContextFiles -contains $normalized
}

Write-Host 'QuisquisLingo 2.0.8+208 Rebranding Verification'
Write-Host 'Script version 1.3.0'
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"

Write-Section '1. Repository root check'

if (-not (Test-Path '.git')) {
    throw 'No .git directory found. Run this script from the repository root.'
}
if (-not (Test-Path 'pubspec.yaml')) {
    throw 'pubspec.yaml not found. Run this script from the Flutter repository root.'
}

$repoRoot = (Get-Location).Path
Write-Pass "Repository root detected: $repoRoot"
Write-Info 'The local parent-folder name is not part of the application identity and is not checked.'

Write-Section '2. Current app version'

$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^\s*version:\s*(.+?)\s*$' |
    Select-Object -First 1

if ($null -eq $versionLine) {
    Write-Review 'pubspec.yaml contains no readable version line.'
} else {
    $currentVersion = $versionLine.Matches[0].Groups[1].Value.Trim()
    Write-Host "Current version: $currentVersion"
    if ($currentVersion -eq $ExpectedVersion) {
        Write-Pass "Version is $ExpectedVersion"
    } else {
        Write-Review "Expected $ExpectedVersion but found $currentVersion"
    }
}

Write-Section '3. Git origin check'

$originFetch = (git remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originFetch)) {
    Write-Review 'Could not read the Git origin URL.'
} else {
    Write-Host "origin: $originFetch"
    if ($originFetch.TrimEnd('/') -eq $ExpectedOrigin.TrimEnd('/')) {
        Write-Pass 'origin points to Quisquisnaut/QuisquisLingo.'
    } else {
        Write-Review "Unexpected origin. Expected $ExpectedOrigin"
    }
}

Write-Section '4. Build active working-tree file inventory'

$gitPaths = @(
    git ls-files --cached --others --exclude-standard |
    ForEach-Object { Normalize-GitPath $_ } |
    Where-Object {
        $_ -and
        $(Split-Path -Leaf $_) -notmatch $VerifierPattern -and
        (Test-Path -LiteralPath $_ -PathType Leaf)
    } |
    Sort-Object -Unique
)

Write-Info "Current tracked/non-ignored untracked files inspected: $($gitPaths.Count)"
Write-Info 'Ignored build/, .dart_tool/, generated binaries, caches, and rollback artifacts are not scanned.'

Write-Section '5. Active filename/path branding check'

$oldNamedPaths = @(
    $gitPaths | Where-Object { $_ -match '(?i)lingogrow' }
)

if ($oldNamedPaths.Count -eq 0) {
    Write-Pass 'No current active file path contains LingoGrow.'
} else {
    Write-Review "$($oldNamedPaths.Count) current active path(s) still contain LingoGrow:"
    $oldNamedPaths | ForEach-Object { Write-Host "  $_" }
}

Write-Section '6. Active file-content branding check'

$textCandidatePaths = @(
    $gitPaths | Where-Object {
        $ext = [System.IO.Path]::GetExtension($_).ToLowerInvariant()
        $BinaryExtensions -notcontains $ext
    }
)

$activeMatches = New-Object System.Collections.Generic.List[object]
$historicalMatches = New-Object System.Collections.Generic.List[object]

foreach ($path in $textCandidatePaths) {
    try {
        $matches = @(
            Select-String -LiteralPath $path -Pattern 'lingogrow' -CaseSensitive:$false -ErrorAction Stop
        )
    } catch {
        Write-Info "Skipped unreadable/non-text file: $path"
        continue
    }

    foreach ($match in $matches) {
        $entry = [PSCustomObject]@{
            Path       = Normalize-GitPath $path
            LineNumber = $match.LineNumber
            Line       = $match.Line.Trim()
        }

        if (Is-HistoricalContextFile $path) {
            $historicalMatches.Add($entry)
        } else {
            $activeMatches.Add($entry)
        }
    }
}

if ($activeMatches.Count -eq 0) {
    Write-Pass 'No LingoGrow references found in active source/config/tests/scripts/current docs.'
} else {
    Write-Review "$($activeMatches.Count) active LingoGrow content occurrence(s) require inspection:"
    foreach ($m in $activeMatches) {
        Write-Host "  $($m.Path):$($m.LineNumber): $($m.Line)"
    }
}

if ($historicalMatches.Count -eq 0) {
    Write-Info 'No historical/context LingoGrow references found in AGENTS.md or CHANGELOG.md.'
} else {
    Write-Host ''
    Write-Info "$($historicalMatches.Count) historical/context occurrence(s) found in allowed files:"
    foreach ($m in $historicalMatches) {
        Write-Host "  $($m.Path):$($m.LineNumber): $($m.Line)"
    }
    Write-Info 'These are permitted only if they genuinely describe old releases/rebranding history.'
}

Write-Section '7. Deleted/renamed old-branded index paths'

$indexOldPaths = @(
    git ls-files |
    ForEach-Object { Normalize-GitPath $_ } |
    Where-Object { $_ -match '(?i)lingogrow' }
)

$staleDeletedOldPaths = @(
    $indexOldPaths | Where-Object { -not (Test-Path -LiteralPath $_) }
)

$currentIndexOldPaths = @(
    $indexOldPaths | Where-Object { Test-Path -LiteralPath $_ }
)

if ($staleDeletedOldPaths.Count -gt 0) {
    Write-Info "$($staleDeletedOldPaths.Count) old-branded Git index path(s) no longer exist in the working tree:"
    $staleDeletedOldPaths | ForEach-Object { Write-Host "  $_" }
    Write-Info 'This is expected before staging a rename/deletion.'
}

if ($currentIndexOldPaths.Count -gt 0) {
    Write-Review "$($currentIndexOldPaths.Count) old-branded tracked path(s) still physically exist:"
    $currentIndexOldPaths | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Pass 'No old-branded tracked path still physically exists.'
}

Write-Section '8. Git working-tree status'
git status --short

Write-Section '9. Diff statistics'
git --no-pager diff --stat

Write-Section '10. Changed-path review'
git --no-pager diff --name-status

Write-Section '11. Diff whitespace/error check'

git --no-pager diff --check
if ($LASTEXITCODE -eq 0) {
    Write-Pass 'git --no-pager diff --check passed.'
} else {
    Write-Review 'git --no-pager diff --check reported a problem. Review the output above.'
}

if ($ShowFullDiff) {
    Write-Section '12. Full diff'
    Write-Host 'Verify that every changed line is required by the 208 technical rebrand.'
    git --no-pager diff
} else {
    Write-Section '12. Full diff'
    Write-Info 'Full diff not printed. Re-run with -ShowFullDiff to display it.'
}

Write-Section '13. Final result'

if ($ReviewCount -eq 0) {
    Write-Pass 'Rebranding verification found no active LingoGrow leftovers or structural problems.'
    Write-Host ''
    Write-Host 'Next step: run your separate full Flutter/project validation script.'
    Write-Host 'Do not commit/push until that validation also succeeds.'
    $exitCode = 0
} else {
    Write-Host "[REVIEW] $ReviewCount verification section(s) need review before accepting build 208."
    Write-Host ''
    Write-Host 'Resolve or explicitly classify the REVIEW items, then run this verifier again.'
    $exitCode = 1
}

Write-Host ''
Write-Host "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
exit $exitCode
