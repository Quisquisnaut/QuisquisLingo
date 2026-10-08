import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/tts_linux_backend.dart';
import 'package:quisquislingo_app/services/tts_windows_backend.dart';

void main() {
  group('eSpeak arguments', () {
    test('spoken text is always separated from options by --', () {
      final arguments = espeakArguments(
        voice: 'it',
        wordsPerMinute: 150,
        wavPath: '/tmp/speech.wav',
        text: 'Buongiorno',
      );

      expect(arguments, [
        '-v',
        'it',
        '-s',
        '150',
        '-w',
        '/tmp/speech.wav',
        '--',
        'Buongiorno',
      ]);
      expect(arguments.indexOf('--'), arguments.length - 2);
    });

    test(
      'course text that looks like an option is passed as text, not parsed',
      () {
        // eSpeak parses options with getopt_long, which scans every argument.
        // Without the -- marker these would be read as flags, and -w would make
        // eSpeak write a file of the course author's choosing.
        for (final hostile in const [
          '-w /home/learner/.bashrc',
          '--stdin',
          '-v en',
          '--path=/etc',
          '-',
        ]) {
          final arguments = espeakArguments(
            voice: 'it',
            wordsPerMinute: 150,
            wavPath: '/tmp/speech.wav',
            text: hostile,
          );

          expect(arguments.last, hostile);
          expect(
            arguments[arguments.length - 2],
            '--',
            reason: 'the option terminator must immediately precede the text',
          );
          // The only -w is the one QQL chose itself.
          expect(arguments.where((argument) => argument == '-w').length, 1);
          expect(arguments[5], '/tmp/speech.wav');
        }
      },
    );
  });

  group('Windows PowerShell candidates', () {
    test('the real system path is preferred over a bare executable name', () {
      final candidates = windowsPowerShellCandidates(systemRoot: r'C:\Windows');

      expect(candidates.first, contains(r'C:\Windows\System32'));
      expect(candidates.first, endsWith(r'\powershell.exe'));
      expect(candidates, contains('powershell.exe'));
    });

    test('a missing SystemRoot still leaves a usable fallback', () {
      expect(windowsPowerShellCandidates(systemRoot: ''), ['powershell.exe']);
      expect(windowsPowerShellCandidates(systemRoot: '   '), [
        'powershell.exe',
      ]);
    });

    test('each startable candidate costs a synthesis timeout, so there are '
        'never more than two', () {
      expect(
        windowsPowerShellCandidates(systemRoot: r'C:\Windows').length,
        lessThanOrEqualTo(2),
      );
    });
  });
}
