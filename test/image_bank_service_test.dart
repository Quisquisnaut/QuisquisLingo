import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';

const _missingManifest =
    'UEsDBBQAAAAIADW5DV2DFtyMAwAAAAEAAAAJAAAAaW1hZ2UucG5nqwAAUEsBAhQDFAAAAAgANbkNXYMW3IwDAAAAAQAAAAkAAAAAAAAAAAAAAIABAAAAAGltYWdlLnBuZ1BLBQYAAAAAAQABADcAAAAqAAAAAAA=';
const _malformedManifest =
    'UEsDBBQAAAAIADW5DV2pXVE3CwAAAAkAAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29uq87LL1HIKs7PAwBQSwMEFAAAAAgANbkNXYMW3IwDAAAAAQAAAAkAAABpbWFnZS5wbmerAABQSwECFAMUAAAACAA1uQ1dqV1RNwsAAAAJAAAAGAAAAAAAAAAAAAAAgAEAAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29uUEsBAhQDFAAAAAgANbkNXYMW3IwDAAAAAQAAAAkAAAAAAAAAAAAAAIABQQAAAGltYWdlLnBuZ1BLBQYAAAAAAgACAH0AAABrAAAAAAA=';
const _unsafeManifestFilename =
    'UEsDBBQAAAAIADW5DV1wF9SNOAAAAD0AAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQqlDSUVAqKMrMTSyqjC9JLcoFCUaABNMyc1LzEnNTQQJ6evqpZZk5egV56Uq1sQBQSwMEFAAAAAgANbkNXYMW3IwDAAAAAQAAAAgAAABldmlsLnBuZ6sAAFBLAQIUAxQAAAAIADW5DV1wF9SNOAAAAD0AAAAYAAAAAAAAAAAAAACAAQAAAABpbWFnZV9iYW5rX21hbmlmZXN0Lmpzb25QSwECFAMUAAAACAA1uQ1dgxbcjAMAAAABAAAACAAAAAAAAAAAAAAAgAFuAAAAZXZpbC5wbmdQSwUGAAAAAAIAAgB8AAAAlwAAAAAA';
const _duplicateId =
    'UEsDBBQAAAAIADW5DV1mlgy1RwAAAHoAAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQSiktUNJRUCooysxNLKqML0ktygUJ++elgoTTMnNS8xJzU0FC+XmpegV56Uq1OgoENIeU56NrLinPh2iOBQBQSwMEFAAAAAgANbkNXYMW3IwDAAAAAQAAAAcAAABvbmUucG5nqwAAUEsDBBQAAAAIADW5DV0VJtv7AwAAAAEAAAAHAAAAdHdvLnBuZ6sEAFBLAQIUAxQAAAAIADW5DV1mlgy1RwAAAHoAAAAYAAAAAAAAAAAAAACAAQAAAABpbWFnZV9iYW5rX21hbmlmZXN0Lmpzb25QSwECFAMUAAAACAA1uQ1dgxbcjAMAAAABAAAABwAAAAAAAAAAAAAAgAF9AAAAb25lLnBuZ1BLAQIUAxQAAAAIADW5DV0VJtv7AwAAAAEAAAAHAAAAAAAAAAAAAACAAaUAAAB0d28ucG5nUEsFBgAAAAADAAMAsAAAAM0AAAAAAA==';
const _missingAsset =
    'UEsDBBQAAAAIADW5DV1W4G7gOAAAAD0AAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQqlDSUVAqKMrMTSyqjC9JLcoFCUaABNMyc1LzEnNTQQK5mcXFmXnpegV56Uq1sQBQSwECFAMUAAAACAA1uQ1dVuBu4DgAAAA9AAAAGAAAAAAAAAAAAAAAgAEAAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29uUEsFBgAAAAABAAEARgAAAG4AAAAAAA==';
const _unsupportedExt =
    'UEsDBBQAAAAIADW5DV3nDoDlMQAAADcAAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQqlDSUVAqKMrMTSyqjC9JLcoFCUaABNMyc1LzEnNTwar00jPTlGpjAVBLAwQUAAAACAA1uQ1d8s5KVggAAAAGAAAABQAAAHguZ2lmc/d0s7BMBABQSwECFAMUAAAACAA1uQ1d5w6A5TEAAAA3AAAAGAAAAAAAAAAAAAAAgAEAAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29uUEsBAhQDFAAAAAgANbkNXfLOSlYIAAAABgAAAAUAAAAAAAAAAAAAAIABZwAAAHguZ2lmUEsFBgAAAAACAAIAeQAAAJIAAAAAAA==';
const _pathTraversalEntry =
    'UEsDBBQAAAAIADW5DV3z9KJVNQAAADoAAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQqlDSUVAqKMrMTSyqjC9JLcoFCUaABNMyc1LzEnNTQQKpZZk5egV56Uq1sQBQSwMEFAAAAAgANbkNXYMW3IwDAAAAAQAAAAsAAAAuLi9ldmlsLnBuZ6sAAFBLAQIUAxQAAAAIADW5DV3z9KJVNQAAADoAAAAYAAAAAAAAAAAAAACAAQAAAABpbWFnZV9iYW5rX21hbmlmZXN0Lmpzb25QSwECFAMUAAAACAA1uQ1dgxbcjAMAAAABAAAACwAAAAAAAAAAAAAAgAFrAAAALi4vZXZpbC5wbmdQSwUGAAAAAAIAAgB/AAAAlwAAAAAA';
const _duplicateBasename =
    'UEsDBBQAAAAIADW5DV3NKjCUNAAAADoAAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQqlDSUVAqKMrMTSyqjC9JLcoFCUaABNMyc1LzEnNTQQLFQFqvIC9dqTYWAFBLAwQUAAAACAA1uQ1dgxbcjAMAAAABAAAACgAAAGEvc2FtZS5wbmerAABQSwMEFAAAAAgANbkNXRUm2/sDAAAAAQAAAAoAAABiL3NhbWUucG5nqwQAUEsBAhQDFAAAAAgANbkNXc0qMJQ0AAAAOgAAABgAAAAAAAAAAAAAAIABAAAAAGltYWdlX2JhbmtfbWFuaWZlc3QuanNvblBLAQIUAxQAAAAIADW5DV2DFtyMAwAAAAEAAAAKAAAAAAAAAAAAAACAAWoAAABhL3NhbWUucG5nUEsBAhQDFAAAAAgANbkNXRUm2/sDAAAAAQAAAAoAAAAAAAAAAAAAAIABlQAAAGIvc2FtZS5wbmdQSwUGAAAAAAMAAwC2AAAAwAAAAAAA';
const _existingId =
    'UEsDBBQAAAAIADW5DV2bjQqUOAAAAD4AAAAYAAAAaW1hZ2VfYmFua19tYW5pZmVzdC5qc29ui65WykxRslJQSq3ILC7JzEtX0lFQKijKzE0sqowvSS3KBclFgATTMnNS8xJzU0ECFXoFQJW1sQBQSwMEFAAAAAgANbkNXYMW3IwDAAAAAQAAAAUAAAB4LnBuZ6sAAFBLAQIUAxQAAAAIADW5DV2bjQqUOAAAAD4AAAAYAAAAAAAAAAAAAACAAQAAAABpbWFnZV9iYW5rX21hbmlmZXN0Lmpzb25QSwECFAMUAAAACAA1uQ1dgxbcjAMAAAABAAAABQAAAAAAAAAAAAAAgAFuAAAAeC5wbmdQSwUGAAAAAAIAAgB5AAAAlAAAAAAA';

Future<File> _fixture(String encoded) async {
  final dir = await Directory.systemTemp.createTemp(
    'quisquislingo_image_bank_test_',
  );
  final file = File('${dir.path}${Platform.pathSeparator}bank.zip');
  await file.writeAsBytes(base64Decode(encoded), flush: true);
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return file;
}

Future<void> _expectFormat(
  String encoded,
  String expectedText, {
  Set<String> existingIds = const {},
}) async {
  final file = await _fixture(encoded);
  await expectLater(
    ImageBankService().importBankZip(file, existingIds: existingIds),
    throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(expectedText),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects ZIP without manifest', () async {
    await _expectFormat(_missingManifest, 'no image_bank_manifest.json');
  });

  test('rejects malformed manifest JSON', () async {
    final file = await _fixture(_malformedManifest);
    await expectLater(
      ImageBankService().importBankZip(file),
      throwsA(anything),
    );
  });

  test('rejects unsafe manifest filename', () async {
    await _expectFormat(_unsafeManifestFilename, 'Unsafe Image Bank filename');
  });

  test('rejects duplicate manifest IDs', () async {
    await _expectFormat(_duplicateId, 'Duplicate Image Bank ID');
  });

  test('rejects IDs that already exist in the app', () async {
    await _expectFormat(
      _existingId,
      'already exists in the app',
      existingIds: const {'existing'},
    );
  });

  test('rejects manifest entry with missing image asset', () async {
    await _expectFormat(_missingAsset, 'Image asset is missing from ZIP');
  });

  test('rejects unsupported image extension', () async {
    await _expectFormat(_unsupportedExt, 'Unsupported Image Bank file format');
  });

  test('rejects path traversal in ZIP entries', () async {
    await _expectFormat(_pathTraversalEntry, 'Unsafe path in Image Bank ZIP');
  });

  test('rejects duplicate basenames in ZIP', () async {
    await _expectFormat(_duplicateBasename, 'duplicate filenames');
  });

  test('rejects an entry that understates its uncompressed size', () async {
    // A ZIP's declared uncompressed size is attacker-controlled: ZipDecoder
    // reports whatever the headers claim, while readBytes() inflates the real
    // payload. Checking only the declared size would let a small claim carry an
    // arbitrarily large image past both the per-image and the total limit.
    final payload = Uint8List.fromList(
      List<int>.filled(ImageBankService.maxImageBytes * 4, 65),
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'image_bank_manifest.json',
          0,
          utf8.encode(
            jsonEncode([
              {'id': 'bomb', 'primary_term': 'Bomb', 'filename': 'bomb.png'},
            ]),
          ),
        ),
      )
      ..addFile(ArchiveFile('bomb.png', payload.length, payload));
    final zipped = Uint8List.fromList(ZipEncoder().encode(archive));

    // Understate every declared uncompressed size, local and central.
    final view = ByteData.sublistView(zipped);
    for (var i = 0; i + 30 < zipped.length; i++) {
      final signature = view.getUint32(i, Endian.little);
      if (signature == 0x02014b50) {
        view.setUint32(i + 24, 500, Endian.little);
      } else if (signature == 0x04034b50) {
        view.setUint32(i + 22, 500, Endian.little);
      }
    }

    final dir = await Directory.systemTemp.createTemp(
      'quisquislingo_image_bank_bomb_',
    );
    // The inflated-size check runs after the app-support directory is
    // resolved, so path_provider has to answer in the test environment.
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (MethodCall call) async => dir.path,
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}${Platform.pathSeparator}bank.zip');
    await file.writeAsBytes(zipped, flush: true);

    // The declared size passes the pre-flight check, so this can only be
    // caught after inflation.
    final decoded = ZipDecoder().decodeBytes(zipped);
    final entry = decoded.files.firstWhere((f) => f.name == 'bomb.png');
    expect(entry.size, lessThan(ImageBankService.maxImageBytes));
    expect(entry.readBytes()!.length, payload.length);

    await expectLater(
      ImageBankService().importBankZip(file),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('exceeds the 50 KB maximum'),
        ),
      ),
    );
  });

  test('security limits remain bounded', () {
    expect(ImageBankService.maxImageBytes, 50 * 1024);
    expect(ImageBankService.maxZipBytes, 50 * 1024 * 1024);
    expect(ImageBankService.maxManifestBytes, 2 * 1024 * 1024);
    expect(ImageBankService.maxArchiveEntries, 5000);
    expect(ImageBankService.maxImportedImages, 2500);
    expect(ImageBankService.maxTotalImageBytes, 50 * 1024 * 1024);
  });
}
