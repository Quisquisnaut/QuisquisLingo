import 'dart:convert';
import 'dart:io';

/// Windows TTS backend based on System.Speech.
///
/// QuisquisLingo intentionally bypasses flutter_tts on Windows because recent
/// plugin/framework combinations can emit platform-channel messages from a
/// non-platform thread. User/course values are passed through child-process
/// environment variables, with spoken text UTF-8/Base64 encoded, so course
/// text is never parsed as PowerShell source code.
Future<bool> speakWithWindowsTts({
  required String text,
  required String language,
  required String voicePreference,
  double rate = 0.5,
}) async {
  if (!Platform.isWindows || text.trim().isEmpty) return false;

  const script = r'''
Add-Type -AssemblyName System.Speech
$requested = $env:QUISQUISLINGO_TTS_LANG
$preference = $env:QUISQUISLINGO_TTS_PREF
$rateValue = [double]$env:QUISQUISLINGO_TTS_RATE
$textBytes = [Convert]::FromBase64String($env:QUISQUISLINGO_TTS_TEXT_B64)
$text = [Text.Encoding]::UTF8.GetString($textBytes)
$base = ($requested -replace '_','-').Split('-')[0].ToLowerInvariant()
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voices = @($synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo })
$candidates = @($voices | Where-Object { $_.Culture.Name.ToLowerInvariant().StartsWith($base) })
if ($candidates.Count -eq 0) { exit 3 }
$exact = @($candidates | Where-Object { $_.Culture.Name.ToLowerInvariant() -eq ($requested -replace '_','-').ToLowerInvariant() })
$pool = if ($exact.Count -gt 0) { $exact } else { $candidates }
if ($preference -ne 'system') {
  $wantedGender = if ($preference -eq 'female') { 'Female' } elseif ($preference -eq 'male') { 'Male' } else { '' }
  if ($wantedGender) {
    $genderPool = @($pool | Where-Object { $_.Gender.ToString() -eq $wantedGender })
    if ($genderPool.Count -gt 0) { $pool = $genderPool }
  }
}
$voice = $pool[0]
$synth.SelectVoice($voice.Name)
$synth.Volume = 100
$synth.Rate = [Math]::Max(-10,[Math]::Min(10,[int](($rateValue - 0.5) * 12)))
$synth.Speak($text)
Write-Output ($voice.Name + '|' + $voice.Culture.Name + '|' + $voice.Gender)
exit 0
''';

  final candidates = <String>['powershell.exe', 'powershell'];
  for (final executable in candidates) {
    Process? process;
    try {
      process = await Process.start(executable, [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ], runInShell: false, environment: {
        ...Platform.environment,
        'QUISQUISLINGO_TTS_LANG': language,
        'QUISQUISLINGO_TTS_PREF': voicePreference,
        'QUISQUISLINGO_TTS_RATE': rate.toString(),
        'QUISQUISLINGO_TTS_TEXT_B64': base64Encode(utf8.encode(text)),
      });
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process?.kill();
          return 124;
        },
      );
      if (exitCode == 0) return true;
      if (exitCode == 3) return false;
    } on ProcessException {
      continue;
    } catch (_) {
      process?.kill();
      return false;
    }
  }
  return false;
}
