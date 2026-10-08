# =============================================================================
# QuisquisLingo - Codex Transcript Snapshot Tool
# =============================================================================
#
# PURPOSE
# -------
# Creates a timestamped copy of the current Codex PowerShell transcript.
#
# This allows you to send the current Codex session transcript to ChatGPT
# without stopping Codex or ending the PowerShell transcript.
#
#
# WHERE TO SAVE THIS SCRIPT
# -------------------------
# Save this file as:
#
#   tools\snapshot_codex_transcript.ps1
#
# inside the QuisquisLingo repository.
#
#
# WORKFLOW
# --------
#
# 1. Open PowerShell in the repository root.
#
# 2. Start recording the terminal session:
#
#      Start-Transcript -Path .\codex_session.txt
#
# 3. Start Codex normally:
#
#      codex
#
# 4. Leave that PowerShell window open while working with Codex.
#
# 5. When you want to send the current session to ChatGPT, leave Codex
#    running and open a SECOND PowerShell window.
#
# 6. In the second PowerShell window, go to the repository root and run:
#
#      .\tools\snapshot_codex_transcript.ps1
#
# 7. This script creates a timestamped snapshot in the repository root,
#    for example:
#
#      codex_session_20260822_225200.txt
#
# 8. Upload that snapshot file to ChatGPT.
#
#    Codex can remain open and the original codex_session.txt continues
#    recording the session.
#
# 9. You can run this script again whenever you want another snapshot.
#    Each snapshot gets a different timestamp, so previous snapshots are
#    preserved.
#
# 10. When the Codex session is completely finished, exit Codex and run:
#
#      Stop-Transcript
#
#
# IMPORTANT
# ---------
# Do not edit or send codex_session.txt itself while PowerShell is actively
# writing to it. Use this script to create a stable snapshot instead.
#
# This script does not stop Codex, stop the transcript, modify source files,
# commit anything to Git, or send anything over the Internet.
#
# =============================================================================


$ErrorActionPreference = "Stop"


# The script is stored in <repository>\tools.
# Its parent directory is therefore the repository root.
$RepoRoot = Split-Path -Parent $PSScriptRoot


# The live transcript produced by PowerShell Start-Transcript.
$Transcript = Join-Path $RepoRoot "codex_session.txt"


# Verify that a transcript exists before attempting to create a snapshot.
if (-not (Test-Path -LiteralPath $Transcript)) {
    Write-Host ""
    Write-Host "ERROR: codex_session.txt was not found."
    Write-Host ""
    Write-Host "Expected location:"
    Write-Host "  $Transcript"
    Write-Host ""
    Write-Host "Start the transcript from the repository root with:"
    Write-Host ""
    Write-Host "  Start-Transcript -Path .\codex_session.txt"
    Write-Host ""
    Write-Host "Then start Codex:"
    Write-Host ""
    Write-Host "  codex"
    Write-Host ""

    exit 1
}


# Add the current date and time so every snapshot has a unique filename.
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$SnapshotName = "codex_session_$Stamp.txt"
$SnapshotPath = Join-Path $RepoRoot $SnapshotName


# Copy the live transcript without modifying or stopping it.
Copy-Item `
    -LiteralPath $Transcript `
    -Destination $SnapshotPath `
    -Force


Write-Host ""
Write-Host "Codex transcript snapshot created successfully."
Write-Host ""
Write-Host "Snapshot:"
Write-Host "  $SnapshotPath"
Write-Host ""
Write-Host "Upload this snapshot to ChatGPT."
Write-Host ""
Write-Host "Codex and the original transcript can continue running normally."
Write-Host ""