import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/import_result.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/import/safe_file_name.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';

import 'support/fake_file_dialog_backend.dart';

/// A source whose reported size lies, delivered in chunks, optionally
/// failing part-way like a disconnected provider.
class _ChunkedFile implements SelectedExternalFile {
  _ChunkedFile(this.displayName, this.chunks, {this.failAfter, this.onChunk});

  @override
  final String displayName;
  @override
  String get sourceFileName => displayName;
  final List<List<int>> chunks;

  /// Deliberately wrong: limits must come from the bytes actually read.
  @override
  int? get reportedSize => 1;
  final int? failAfter;
  final void Function(int index)? onChunk;

  @override
  ExternalFileSource get source => ExternalFileSource.memory;

  @override
  Future<Stream<List<int>>> openRead() async =>
      Stream.fromIterable(Iterable.generate(chunks.length)).asyncMap((
        index,
      ) async {
        onChunk?.call(index);
        if (failAfter != null && index >= failAfter!) {
          throw StateError('provider disconnected');
        }
        return chunks[index];
      });
}

void main() {
  late Directory support;
  late ImportStager stager;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_tranche1_');
    stager = ImportStager(supportDirectory: () async => support);
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  Future<List<FileSystemEntity>> leftovers() async {
    final directory = await stager.stagingDirectory();
    return await directory.exists() ? directory.listSync() : const [];
  }

  group('safe display names', () {
    test('path, control characters, dots, reserved names, length', () {
      expect(safeDisplayName(r'C:\Users\me\cat.png'), 'cat.png');
      expect(safeDisplayName('/home/me/../cat.png'), 'cat.png');
      expect(safeDisplayName('ca\u0000t\u0007.png'), 'cat.png');
      expect(safeDisplayName('cat.png. . '), 'cat.png');
      expect(safeDisplayName('..'), 'file');
      expect(safeDisplayName(''), 'file');
      expect(safeDisplayName('CON.txt'), '_CON.txt');
      expect(safeDisplayName('lpt1'), '_lpt1');
      final long = safeDisplayName('${'a' * 300}.mp3');
      expect(long.length, 120);
      expect(long, endsWith('.mp3'));
    });
  });

  group('selected files on disk', () {
    test(
      'an ordinary file opens; a folder or a missing file does not',
      () async {
        final file = File('${support.path}${Platform.pathSeparator}song.mp3')
          ..writeAsBytesSync([1, 2, 3]);
        final opened = await FileSystemSelectedFile(file.path).openRead();
        expect(await opened.expand((c) => c).toList(), [1, 2, 3]);
        expect(await isOrdinaryFile(file.path), isTrue);

        final folder = Directory(
          '${support.path}${Platform.pathSeparator}x.mp3',
        )..createSync();
        await expectLater(
          FileSystemSelectedFile(folder.path).openRead(),
          throwsA(isA<ImportAccessException>()),
        );
        expect(await isOrdinaryFile(folder.path), isFalse);
        await expectLater(
          FileSystemSelectedFile('${support.path}/gone.mp3').openRead(),
          throwsA(
            isA<ImportAccessException>().having(
              (e) => e.message,
              'message',
              contains('no longer there'),
            ),
          ),
        );
      },
    );

    test('a symbolic link is refused even when it points at a file', () async {
      final target = File('${support.path}${Platform.pathSeparator}real.png')
        ..writeAsBytesSync([1]);
      final link = Link('${support.path}${Platform.pathSeparator}link.png');
      try {
        link.createSync(target.path);
      } on FileSystemException {
        markTestSkipped('This system does not allow creating symbolic links.');
        return;
      }
      await expectLater(
        FileSystemSelectedFile(link.path).openRead(),
        throwsA(isA<ImportAccessException>()),
      );
      expect(await isOrdinaryFile(link.path), isFalse);
    });
  });

  test('a fixed-name import refuses a link named import.json', () async {
    final real = File('${support.path}${Platform.pathSeparator}real.json')
      ..writeAsStringSync('{}');
    final imports = Directory('${support.path}${Platform.pathSeparator}in')
      ..createSync();
    try {
      Link(
        '${imports.path}${Platform.pathSeparator}import.json',
      ).createSync(real.path);
    } on FileSystemException {
      markTestSkipped('This system does not allow creating symbolic links.');
      return;
    }
    final transfer = CustomCourseTransferService(
      directory: () async => imports,
      fileDialogs: FileDialogService(stager: stager),
    );
    await expectLater(
      transfer.importCourse(),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('is not an ordinary file'),
        ),
      ),
    );
  });

  group('staging', () {
    test(
      'counts actual bytes, not the reported size, and hashes them',
      () async {
        final bytes = List<int>.generate(3000, (i) => i % 251);
        final staged = await stager.stage(
          _ChunkedFile('a.bin', [bytes.sublist(0, 1000), bytes.sublist(1000)]),
          maxBytes: 3000,
        );
        expect(staged.length, 3000);
        expect(staged.sha256, '${sha256.convert(bytes)}');
        expect(await staged.readBytes(), bytes);
        await staged.discard();
        expect(await leftovers(), isEmpty);
      },
    );

    test('one byte over the limit stops reading and leaves nothing', () async {
      var chunksRead = 0;
      await expectLater(
        stager.stage(
          _ChunkedFile('big.bin', [
            List.filled(10, 0),
            List.filled(1, 0),
            List.filled(1000, 0),
          ], onChunk: (_) => chunksRead++),
          maxBytes: 10,
        ),
        throwsA(isA<ImportTooLargeException>()),
      );
      expect(chunksRead, 2, reason: 'no more is read after the limit');
      expect(await leftovers(), isEmpty);
    });

    test('an empty file is refused', () async {
      await expectLater(
        stager.stage(_ChunkedFile('empty.bin', const []), maxBytes: 10),
        throwsA(isA<ImportEmptyException>()),
      );
      expect(await leftovers(), isEmpty);
    });

    test('a source failing part-way is an access failure', () async {
      await expectLater(
        stager.stage(
          _ChunkedFile('cut.bin', [
            [1],
            [2],
          ], failAfter: 1),
          maxBytes: 10,
        ),
        throwsA(isA<ImportAccessException>()),
      );
      expect(await leftovers(), isEmpty);
    });

    test('cancelling mid-file removes the staging copy', () async {
      final token = CancellationToken();
      await expectLater(
        stager.stage(
          _ChunkedFile('slow.bin', [
            [1],
            [2],
            [3],
          ], onChunk: (index) => index == 1 ? token.cancel() : null),
          maxBytes: 10,
          token: token,
        ),
        throwsA(isA<ImportCancelledException>()),
      );
      expect(await leftovers(), isEmpty);
    });

    test('leftovers from an interrupted import are removed', () async {
      final directory = await stager.stagingDirectory();
      await directory.create(recursive: true);
      File(
        '${directory.path}${Platform.pathSeparator}old.part',
      ).writeAsBytesSync([1]);
      await stager.removeLeftovers();
      expect(await leftovers(), isEmpty);
    });
  });

  group('a multiple selection', () {
    MemorySelectedFile file(String name, int size) =>
        MemorySelectedFile(name, Uint8List(size)..fillRange(0, size, 1));

    test('100 files at most; the rest are not processed', () async {
      final batch = await stager.stageBatch([
        for (var i = 0; i < 101; i++) file('f$i.bin', 1),
      ], maxBytesPerFile: 10);
      expect(batch.count(ImportItemOutcome.staged), 100);
      expect(
        batch.items.last.outcome,
        ImportItemOutcome.notProcessedBatchLimit,
      );
      await batch.discardAll();
    });

    test(
      'the batch byte limit stops the batch; bad files are reported',
      () async {
        final batch = await stager.stageBatch(
          [
            file('ok1.bin', 40),
            MemorySelectedFile('empty.bin', Uint8List(0)),
            file('huge.bin', 51),
            file('ok2.bin', 40),
            file('over.bin', 30),
            file('after.bin', 1),
          ],
          maxBytesPerFile: 50,
          maxBatchBytes: 100,
        );
        expect(batch.items.map((i) => i.outcome), [
          ImportItemOutcome.staged,
          ImportItemOutcome.malformed,
          ImportItemOutcome.tooLarge,
          ImportItemOutcome.staged,
          ImportItemOutcome.notProcessedBatchLimit,
          ImportItemOutcome.notProcessedBatchLimit,
        ]);
        expect(batch.summaryLines(), [
          'Selected: 6',
          'Ready: 2',
          'Unreadable or damaged: 1',
          'Too large: 1',
          'Not processed: batch limit: 2',
        ]);
        await batch.discardAll();
        expect(await leftovers(), isEmpty);
      },
    );

    test('cancel halfway keeps what was staged and stops the rest', () async {
      final token = CancellationToken();
      final batch = await stager.stageBatch(
        [
          file('a.bin', 1),
          _ChunkedFile('b.bin', [
            [1],
            [2],
          ], onChunk: (index) => index == 1 ? token.cancel() : null),
          file('c.bin', 1),
        ],
        maxBytesPerFile: 10,
        token: token,
      );
      expect(batch.items.map((i) => i.outcome), [
        ImportItemOutcome.staged,
        ImportItemOutcome.cancelled,
        ImportItemOutcome.cancelled,
      ]);
      await batch.discardAll();
      expect(await leftovers(), isEmpty);
    });
  });

  group('Open from…', () {
    late FakeFileDialogBackend backend;
    late FileDialogService dialogs;

    setUp(() {
      backend = FakeFileDialogBackend();
      dialogs = FileDialogService(backend: backend, stager: stager);
    });

    test('bytes over the real limit are reported as too large', () async {
      backend.onOpen = () async =>
          FileDialogResult.opened('big.json', Uint8List(11));
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 10,
        artifact: 'test',
      );
      expect(result.outcome, FileDialogOutcome.tooLarge);
      expect(result.displayName, 'big.json');
      expect(await leftovers(), isEmpty);
    });

    test('a file within the limit is returned and not left staged', () async {
      backend.onOpen = () async => FileDialogResult.opened(
        'ok.json',
        Uint8List.fromList(utf8.encode('{}')),
      );
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 10,
        artifact: 'test',
      );
      expect(result.outcome, FileDialogOutcome.opened);
      expect(utf8.decode(result.bytes!), '{}');
      expect(await leftovers(), isEmpty);
    });

    test('several files are staged with one result each', () async {
      backend.onOpenMany = [
        MemorySelectedFile('a.mp3', Uint8List(3)..[0] = 1),
        MemorySelectedFile('b.mp3', Uint8List(0)),
      ];
      final picked = await dialogs.openFiles(
        extensions: const ['mp3'],
        maxBytesPerFile: 10,
        artifact: 'test',
      );
      expect(picked.batch!.items.map((i) => i.outcome), [
        ImportItemOutcome.staged,
        ImportItemOutcome.malformed,
      ]);
      await picked.batch!.discardAll();
    });

    test('cancel is still silent', () async {
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 10,
        artifact: 'test',
      );
      expect(result.outcome, FileDialogOutcome.cancelled);
    });
  });
}
