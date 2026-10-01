import 'exercise_copy_de.dart';
import 'exercise_copy_en.dart';
import 'exercise_copy_es.dart';
import 'exercise_copy_fr.dart';
import 'exercise_copy_it.dart';
import 'exercise_copy_nl.dart';
import 'exercise_copy_pt.dart';

/// The learner panel's exercise headings and instruction lines, one catalog
/// per instruction language (Build 260 Revision 0, owner decisions of
/// 1 October 2026: English, Spanish, Italian, German, Portuguese, Dutch and
/// French). A Course whose base language has no catalog gets English; a key
/// a catalog lacks falls back to English.
const exerciseCopyCatalogs = <String, Map<String, String>>{
  'en': exerciseCopyEn,
  'es': exerciseCopyEs,
  'it': exerciseCopyIt,
  'de': exerciseCopyDe,
  'pt': exerciseCopyPt,
  'nl': exerciseCopyNl,
  'fr': exerciseCopyFr,
};
