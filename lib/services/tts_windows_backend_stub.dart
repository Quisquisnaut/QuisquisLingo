List<String> windowsPowerShellCandidates({String? systemRoot}) {
  final root = (systemRoot ?? '').trim();
  return <String>[
    if (root.isNotEmpty)
      '$root\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
    'powershell.exe',
  ];
}

Future<bool> speakWithWindowsTts({
  required String text,
  required String language,
  required String voicePreference,
  double rate = 0.5,
  Future<void> Function(String)? onDiagnostic,
}) async => false;
