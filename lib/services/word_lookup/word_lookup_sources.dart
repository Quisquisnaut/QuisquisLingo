import '../../models/course_models.dart';
import '../course_language_resolver.dart';
import '../publication_service.dart';
import 'word_lookup.dart';
import 'word_lookup_articles.dart';

/// Where Word Lookup reads its entries (Build 265): the GuideBook of the
/// whole Course, locked Lessons included, in Course order.
///
/// Since Build 266 (GuideBook modules) it reads the Words & Expressions of
/// every module, never Sentences (a sentence's translation could give
/// answers away), with each entry's Context and picture.
///
/// Nothing when the Course's Use GuideBook is off. The learner app reads
/// Published Lessons and Published GuideBooks only; the Course Editor
/// Preview ([includeDrafts]) reads Drafts too, as its Open GuideBook does.
abstract final class WordLookupSources {
  static List<WordLookupSourceEntry> forCourse(
    Course course, {
    bool includeDrafts = false,
    PublicationService publication = const PublicationService(),
  }) {
    if (!course.useGuidebook) return const [];
    final entries = <WordLookupSourceEntry>[];
    for (var index = 0; index < course.lessons.length; index++) {
      final lesson = course.lessons[index];
      if (!includeDrafts && !lesson.publicationState.isPublished) continue;
      final guidebook = includeDrafts
          ? lesson.guidebook
          : publication.learnerGuidebook(lesson.guidebook);
      for (final word in guidebook.words) {
        entries.add(
          WordLookupSourceEntry(
            id: word.id,
            target: word.target,
            source: word.source,
            context: word.context,
            picture: word.picture,
            lessonIndex: index,
          ),
        );
      }
    }
    return entries;
  }

  /// The index of [course], built once per Course object (a Course is
  /// immutable; an edited Course is a new object).
  static WordLookupIndex indexFor(Course course, {bool includeDrafts = false}) {
    final cache = includeDrafts ? _withDrafts : _published;
    return cache[course] ??= WordLookupIndex.build(
      forCourse(course, includeDrafts: includeDrafts),
      articles: WordLookupArticles.forLanguage(
        CourseLanguageResolver.learning(course).code,
      ),
    );
  }

  static final Expando<WordLookupIndex> _published = Expando();
  static final Expando<WordLookupIndex> _withDrafts = Expando();
}
