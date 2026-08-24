$ErrorActionPreference = "Stop"

# Always run from the repository root, even if this script is launched
# from another working directory.
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host ""
Write-Host "QuisquisLingo release validation"
Write-Host "================================"
Write-Host ""

# Show exactly what source revision is being validated.
Write-Host "Repository:"
Write-Host "  Path:   $RepoRoot"

$Branch = git branch --show-current
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Unable to determine Git branch."
    exit $LASTEXITCODE
}

$Commit = git rev-parse --short HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Unable to determine Git commit."
    exit $LASTEXITCODE
}

Write-Host "  Branch: $Branch"
Write-Host "  Commit: $Commit"
Write-Host ""

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host ">>> $Name"
    Write-Host "------------------------------------------------------------"
    Write-Host ""

    & $Command

    $ExitCode = $LASTEXITCODE

    if ($ExitCode -ne 0) {
        Write-Host ""
        Write-Host "============================================================"
        Write-Host "FAILED: $Name"
        Write-Host "Exit code: $ExitCode"
        Write-Host "============================================================"
        exit $ExitCode
    }

    Write-Host ""
    Write-Host "PASSED: $Name"
}

Run-Step "Full Flutter test suite" {
    flutter test --no-pub --concurrency=1
}

Run-Step "Bundled course validator" {
    python tools/validate_courses.py
}

Run-Step "Image Bank validator" {
    python tools/validate_images.py
}

Run-Step "Git diff check" {
    git diff --check
}

Write-Host ""
Write-Host "============================================================"
Write-Host "ALL RELEASE VALIDATION CHECKS PASSED"
Write-Host "============================================================"
Write-Host ""
Write-Host "Branch: $Branch"
Write-Host "Commit: $Commit"
Write-Host ""