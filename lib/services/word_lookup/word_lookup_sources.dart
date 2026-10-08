import '../../models/course_models.dart';
import '../course_language_resolver.dart';
import '../publication_service.dart';
import 'word_lookup.dart';
import 'word_lookup_articles.dart';

/// Where Word Lookup reads its entries (Build 265): the GuideBook vocabulary
/// of the whole Course, locked Lessons included, in Course order.
///
/// Nothing when the Course's Use GuideBook is off. The learner app reads
/// Published Lessons and Published GuideBook entries only; the Course Editor
/// Preview ([includeDrafts]) reads Drafts too, as its Open GuideBook does.
/// Build 266 (GuideBook modules) changes only this adapter.
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
      for (final content in guidebook.content) {
        if (content.kind != 'vocabulary') continue;
        entries.add(
          WordLookupSourceEntry(
            id: content.id,
            text: content.text,
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
