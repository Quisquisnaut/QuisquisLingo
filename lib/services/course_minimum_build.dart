import '../models/course_models.dart';
import 'editor_notes.dart';
import 'lesson_icon_pictures.dart';
import 'page_blocks.dart';
import 'picture_answers.dart';
import 'plural_pictures.dart';

/// The oldest build of QuisquisLingo that can play a Course (Build 273
/// Revision 9): each feature listed here, added by a build that an earlier
/// one would misread, raises the Course's `minimumAppBuild` when a confirmed
/// save uses it, so an earlier build refuses the Course instead of showing it
/// wrong. Each feature keeps its own rule; this is their one list, in the
/// order the Course Editor applied them. A new such feature adds its rule
/// here.
abstract final class CourseMinimumBuild {
  /// [course] with its `minimumAppBuild` raised for each feature it uses,
  /// never lowered.
  static Course stamp(Course course) {
    // Build 258: a Course with a Page needs a build that draws Pages.
    var stamped = PageBlocks.withMinimumAppBuild(course);
    // Build 263 Revision 2: so does one that asks for another picture look.
    stamped = PictureAnswers.withMinimumAppBuild(stamped);
    // Build 264 Revision 8: and one whose Lesson icon is a library picture.
    stamped = LessonIconPictures.withMinimumAppBuild(stamped);
    // Build 265 Revision 11: and one that marks a picture plural.
    stamped = PluralPictures.withMinimumAppBuild(stamped);
    // Build 267 Revision 8: and one whose exercises carry Editor Notes.
    return EditorNotes.withMinimumAppBuild(stamped);
  }
}
