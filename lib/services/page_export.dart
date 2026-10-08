import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/course_models.dart';
import 'inline_marks.dart';

/// Build 258 Revision 4: a Page as a PDF to share, save or print (owner
/// decisions of 29 September 2026). The PDF holds the page exactly as the
/// app draws it, cut into A4 pages, so every script, picture and format
/// looks as on screen and no font has to be bundled; its text is not
/// selectable. Pure image handling: capturing the page belongs to the
/// widget that shows it.
abstract final class PageExport {
  /// A4 with 36-point margins.
  static final PdfPageFormat format = PdfPageFormat.a4.copyWith(
    marginLeft: 36,
    marginRight: 36,
    marginTop: 36,
    marginBottom: 36,
  );

  /// The PDF of [image], the page drawn at any resolution, cut into as many
  /// A4 pages as its height needs.
  static Future<Uint8List> pdfFromImage(
    ui.Image image, {
    required String title,
  }) async {
    final contentWidth = format.availableWidth;
    final contentHeight = format.availableHeight;
    final pixelsPerPoint = image.width / contentWidth;
    final sliceHeight = (contentHeight * pixelsPerPoint).floor();
    final document = pw.Document(
      title: title,
      producer: 'QuisquisLingo',
      creator: 'QuisquisLingo',
    );
    for (var top = 0; top < image.height; top += sliceHeight) {
      final height = top + sliceHeight > image.height
          ? image.height - top
          : sliceHeight;
      final slice = await _crop(image, top, height);
      document.addPage(
        pw.Page(
          pageFormat: format,
          build: (_) => pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.Image(
              pw.MemoryImage(slice),
              width: contentWidth,
              height: height / pixelsPerPoint,
            ),
          ),
        ),
      );
    }
    return document.save();
  }

  static Future<Uint8List> _crop(ui.Image image, int top, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, top.toDouble(), image.width.toDouble(), height * 1.0),
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), height * 1.0),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final slice = await picture.toImage(image.width, height);
    picture.dispose();
    try {
      final data = await slice.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      slice.dispose();
    }
  }

  /// The page's words, top to bottom, without marks: what a Linux share
  /// (an email body) carries and what names the file.
  static String plainText(List<PromptElement> blocks) => [
    for (final block in blocks)
      if (block.isText && block.text.trim().isNotEmpty)
        block.text
            .split('\n')
            .map(InlineMarks.plain)
            .where((line) => line.trim().isNotEmpty)
            .join('\n')
      else if (block.isLink && block.url.trim().isNotEmpty)
        '${block.text.trim().isEmpty ? 'Video' : block.text.trim()}: ${block.url.trim()}',
  ].join('\n\n');

  /// The credits line under an exported page: the Course, its rights holder
  /// (else its original creator) and licence, and QuisquisLingo.
  static String credits(Course course) {
    final holders = course.rightsHolders
        .map((holder) => holder.name.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');
    final creator = course.originalCourseCreator.displayName.trim();
    final owner = holders.isNotEmpty ? holders : creator;
    return [
      course.title.trim(),
      if (owner.isNotEmpty) '© $owner',
      if (course.license.trim().isNotEmpty) course.license.trim(),
      'QuisquisLingo',
    ].join(' · ');
  }

  /// `QQL_page_<course>_<first words>`, safe on every system.
  static String baseName(Course course, List<PromptElement> blocks) {
    String safe(String value, int length) {
      final cleaned = value
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      return cleaned.length > length ? cleaned.substring(0, length) : cleaned;
    }

    final firstText = blocks
        .where((block) => block.isText && block.text.trim().isNotEmpty)
        .map((block) => InlineMarks.plain(block.text.split('\n').first))
        .firstOrNull;
    final course_ = safe(course.title, 24);
    final page = safe(firstText ?? '', 32);
    return [
      'QQL_page',
      course_.isEmpty ? 'course' : course_,
      if (page.isNotEmpty) page,
    ].join('_');
  }
}
