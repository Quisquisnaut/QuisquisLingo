# Builds the bundled Story avatars (Build 256 Revision 5): one 256 x 256 PNG
# per mascot, the whole figure fitted into the square on a transparent
# background, from the mascot originals in design/mascots (Build 264: the app
# ships WebP copies). Deterministic: run it again after changing a mascot. Uses .NET System.Drawing, so it runs on Windows PowerShell 5.1.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/make_avatars.ps1
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$sources = [ordered]@{
  cat    = 'cat-celebrating_tr.png'
  dog    = 'dog-laughing-pencil_tr.png'
  kid    = 'kid_reading.png'
  monkey = 'monkey-yawning_tr.png'
  robot  = 'robot_speaking.png'
}
$size = 256
$outDir = Join-Path $root 'assets\avatars'
New-Item -ItemType Directory -Force $outDir | Out-Null
foreach ($name in $sources.Keys) {
  $src = [System.Drawing.Bitmap]::FromFile((Join-Path $root ('design\mascots\' + $sources[$name])))
  try {
    $scale = [Math]::Min($size / $src.Width, $size / $src.Height)
    $w = [int][Math]::Round($src.Width * $scale)
    $h = [int][Math]::Round($src.Height * $scale)
    $dst = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
      $g = [System.Drawing.Graphics]::FromImage($dst)
      try {
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.DrawImage($src, [int](($size - $w) / 2), [int](($size - $h) / 2), $w, $h)
      } finally {
        $g.Dispose()
      }
      $out = Join-Path $outDir ($name + '.png')
      $dst.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
      Write-Output ("{0}.png {1}x{2} figure, {3} bytes" -f $name, $w, $h, (Get-Item $out).Length)
    } finally {
      $dst.Dispose()
    }
  } finally {
    $src.Dispose()
  }
}
