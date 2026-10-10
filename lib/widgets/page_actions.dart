import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_models.dart';
import '../services/file_dialog_service.dart';
import '../services/page_export.dart';
import '../services/storage/qql_storage.dart';
import 'page_card.dart';

/// Build 258 Revision 4 (owner decisions of 29 September 2026): Share,
/// Save PDF and Print under a Page, when its Course allows it
/// (`Course.allowPageSharing`, on by default). Share opens the system sheet
/// (email, messages, files; Print on iOS); on Linux it shares the page's
/// text. Save offers Save as… where the system dialog exists and the Quick
/// Export folder `Export/Pages`. Print is two steps on desktops: the PDF
/// opens in the default viewer, which prints it (no printing plugin).
class PageActionsBar extends StatefulWidget {
  const PageActionsBar({
    super.key,
    required this.course,
    required this.blocks,
    required this.pictureBuilder,
  });

  final Course course;
  final List<PromptElement> blocks;
  final Widget Function(PromptElement picture, double width) pictureBuilder;

  /// Test seams: how the page is drawn into an image, shared, exported and
  /// opened, and which system this is.
  static Future<ui.Image> Function(BuildContext context, Widget page) capture =
      PageCapture.capture;
  static Future<void> Function(ShareParams params) share = (params) async {
    await SharePlus.instance.share(params);
  };
  static Future<QuickExportFolder> Function() exportFolder = () =>
      QqlStorage().exportFolder(QqlStorageRole.pageExports);
  static Future<Directory> Function() temporaryDirectory =
      getTemporaryDirectory;
  static Future<bool> Function(Uri file) openFile = launchUrl;
  static FileDialogService Function() fileDialogs = FileDialogService.new;
  static bool Function() isDesktop = () =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool Function() sharesTextOnly = () => !kIsWeb && Platform.isLinux;

  /// The folders Print makes in the temporary folder (Build 270 Revision 6).
  static const printFolderPrefix = 'QQL_print_';

  @override
  State<PageActionsBar> createState() => _PageActionsBarState();
}

enum _Save { saveAs, quickExport }

class _PageActionsBarState extends State<PageActionsBar> {
  bool _busy = false;

  static const printFolderPrefix = PageActionsBar.printFolderPrefix;

  /// Earlier prints' folders: their PDF viewers have read them by now. A file
  /// still open is left for the next time.
  static Future<void> _removeEarlierPrints(Directory temporary) async {
    try {
      await for (final entity in temporary.list(followLinks: false)) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (entity is Directory && name.startsWith(printFolderPrefix)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  late final FileDialogService _dialogs = PageActionsBar.fileDialogs();

  String get _baseName => PageExport.baseName(widget.course, widget.blocks);

  /// The page as it goes into the PDF: the learner's renderer in its print
  /// form and the credits line.
  Widget _printable() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageCardView(
        blocks: widget.blocks,
        pictureBuilder: widget.pictureBuilder,
        background: Colors.white,
        forExport: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(
          PageExport.credits(widget.course),
          key: const Key('page-export-credits'),
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ),
    ],
  );

  Future<Uint8List> _pdf() async {
    final image = await PageActionsBar.capture(context, _printable());
    try {
      return await PageExport.pdfFromImage(image, title: widget.course.title);
    } finally {
      image.dispose();
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    String? message;
    try {
      message = await action();
    } catch (error) {
      message = 'The page could not be exported: $error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text(message)),
      );
    }
  }

  Rect? _origin() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share() => _run(() async {
    final origin = _origin();
    if (PageActionsBar.sharesTextOnly()) {
      await PageActionsBar.share(
        ShareParams(
          subject: widget.course.title,
          text:
              '${PageExport.plainText(widget.blocks)}\n\n${PageExport.credits(widget.course)}',
          sharePositionOrigin: origin,
        ),
      );
      return null;
    }
    final pdf = await _pdf();
    await PageActionsBar.share(
      ShareParams(
        subject: widget.course.title,
        files: [
          XFile.fromData(
            pdf,
            name: '$_baseName.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        fileNameOverrides: ['$_baseName.pdf'],
        sharePositionOrigin: origin,
      ),
    );
    return null;
  });

  Future<void> _save(_Save how) => _run(() async {
    final pdf = await _pdf();
    if (how == _Save.saveAs) {
      final result = await _dialogs.saveBytes(
        bytes: pdf,
        suggestedName: '$_baseName.pdf',
        extensions: const ['pdf'],
        artifact: 'page-pdf',
      );
      return switch (result.outcome) {
        FileDialogOutcome.saved => 'Page saved as ${result.displayName}.',
        FileDialogOutcome.cancelled => null,
        _ =>
          'The page could not be saved there. Quick Export saves it to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.pageExports)}.',
      };
    }
    final folder = await PageActionsBar.exportFolder();
    final written = await folder.write(
      baseName: _baseName,
      extension: 'pdf',
      bytes: pdf,
    );
    return 'Page saved to ${written.location}.';
  });

  Future<void> _print() => _run(() async {
    final pdf = await _pdf();
    // Build 270 Revision 6: a new folder of QQL's own for each print (not a
    // name another user of the computer could prepare), and the earlier
    // prints are removed.
    final temporary = await PageActionsBar.temporaryDirectory();
    await _removeEarlierPrints(temporary);
    final directory = await temporary.createTemp(printFolderPrefix);
    final file = File(
      '${directory.path}${Platform.pathSeparator}$_baseName.pdf',
    );
    await file.writeAsBytes(pdf, flush: true);
    final opened = await PageActionsBar.openFile(Uri.file(file.path));
    return opened
        ? 'The page opened in your PDF viewer: print it from there.'
        : 'No PDF viewer opened the page. Save it and print it from a PDF viewer.';
  });

  @override
  Widget build(BuildContext context) {
    final saveAs = _dialogs.isAvailable;
    return Wrap(
      key: const Key('page-actions'),
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const Key('page-share'),
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
        PopupMenuButton<_Save>(
          key: const Key('page-save'),
          enabled: !_busy,
          tooltip: 'Save the page as a PDF',
          onSelected: _save,
          itemBuilder: (_) => [
            if (saveAs)
              const PopupMenuItem(
                key: Key('page-save-as'),
                value: _Save.saveAs,
                child: Text('Save as…'),
              ),
            PopupMenuItem(
              key: const Key('page-quick-export'),
              value: _Save.quickExport,
              child: Text(
                'Quick Export to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.pageExports)}',
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined),
                SizedBox(width: 8),
                Text('Save PDF'),
              ],
            ),
          ),
        ),
        if (PageActionsBar.isDesktop())
          OutlinedButton.icon(
            key: const Key('page-print'),
            onPressed: _busy ? null : _print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
      ],
    );
  }
}

/// Draws a widget off screen at a fixed width and returns it as an image:
/// the page as it goes into a PDF, in the light theme, with its pictures
/// loaded.
abstract final class PageCapture {
  /// The printed width in logical pixels and how many image pixels each
  /// one becomes.
  static const width = 560.0;
  static const pixelRatio = 2.5;

  static Future<ui.Image> capture(BuildContext context, Widget page) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey();
    final light = ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: Theme.of(context).colorScheme.primary,
    );
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -(width * 4),
        top: 0,
        width: width,
        child: IgnorePointer(
          child: Theme(
            data: light,
            child: Material(
              color: Colors.white,
              child: RepaintBoundary(key: key, child: page),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      // Let pictures load (Course media is read from disk).
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return await boundary.toImage(pixelRatio: pixelRatio);
    } finally {
      entry.remove();
    }
  }
}
