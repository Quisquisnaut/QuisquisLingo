import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'profile_service.dart';
import 'publication_service.dart';

class VocabularyReviewEntry {
  const VocabularyReviewEntry({
    required this.identity,
    required this.contentId,
    required this.fingerprint,
    required this.prompt,
    required this.answer,
    this.supplementary = const [],
  });

  final String identity;
  final String contentId;
  final String fingerprint;
  final String prompt;
  final String answer;
  final List<String> supplementary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyReviewEntry &&
          identity == other.identity &&
          contentId == other.contentId &&
          fingerprint == other.fingerprint &&
          prompt == other.prompt &&
          answer == other.answer &&
          _sameStrings(supplementary, other.supplementary);

  @override
  int get hashCode => Object.hash(
    identity,
    contentId,
    fingerprint,
    prompt,
    answer,
    Object.hashAll(supplementary),
  );
}

class VocabularyReviewState {
  const VocabularyReviewState({
    this.encountered = false,
    this.needsReinforcement = false,
  });

  final bool encountered;
  final bool needsReinforcement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyReviewState &&
          encountered == other.encountered &&
          needsReinforcement == other.needsReinforcement;

  @override
  int get hashCode => Object.hash(encountered, needsReinforcement);
}

class VocabularyReviewService {
  VocabularyReviewService({
    ProfileService? profiles,
    PublicationService publication = const PublicationService(),
  }) : _profiles = profiles ?? ProfileService(),
       _publication = publication;

  static const int _storageVersion = 1;
  static const List<String> _separators = [' = ', ' → ', ' - ', ':'];

  final ProfileService _profiles;
  final PublicationService _publication;

  List<VocabularyReviewEntry> resolveEntries(Course course, Lesson lesson) {
    if (!course.useGuidebook) return const [];
    final guidebook = _publication.learnerGuidebook(lesson.guidebook);
    final parsed = <_ParsedVocabulary>[];
    for (final content in guidebook.content) {
      if (content.kind != 'vocabulary') continue;
      final pair = _parsePair(content.text);
      if (pair == null) continue;
      final supplementary = const <String>[];
      final fingerprint = _digest(
        jsonEncode(['qql232-v1', pair.prompt, pair.answer, supplementary]),
      );
      parsed.add(
        _ParsedVocabulary(
          contentId: content.id.trim(),
          fingerprint: fingerprint,
          prompt: pair.prompt,
          answer: pair.answer,
        ),
      );
    }

    final idCounts = <String, int>{};
    for (final item in parsed) {
      if (item.contentId.isNotEmpty) {
        idCounts.update(
          item.contentId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final idOccurrences = <String, int>{};
    final fingerprintOccurrences = <String, int>{};
    return [
      for (final item in parsed)
        VocabularyReviewEntry(
          identity: item.contentId.isNotEmpty
              ? _contentIdentity(item.contentId, idCounts, idOccurrences)
              : _fallbackIdentity(item.fingerprint, fingerprintOccurrences),
          contentId: item.contentId,
          fingerprint: item.fingerprint,
          prompt: item.prompt,
          answer: item.answer,
        ),
    ];
  }

  Future<List<VocabularyReviewEntry>> eligibleEntries(
    Course course,
    Lesson lesson,
  ) async {
    final entries = resolveEntries(course, lesson);
    final eligible = <VocabularyReviewEntry>[];
    for (final entry in entries) {
      final state = await stateFor(course.courseId, lesson.lessonId, entry);
      if (!state.encountered || state.needsReinforcement) {
        eligible.add(entry);
      }
    }
    return eligible;
  }

  Future<VocabularyReviewState> stateFor(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  ) async {
    final document = await _readDocument(courseId);
    final lessons = document['lessons'];
    if (lessons is! Map) return const VocabularyReviewState();
    final lesson = lessons[lessonId];
    if (lesson is! Map) return const VocabularyReviewState();
    final raw = lesson[entry.identity];
    if (raw is! Map || raw['fingerprint'] != entry.fingerprint) {
      return const VocabularyReviewState();
    }
    final encountered = raw['encountered'];
    final needsReinforcement = raw['needsReinforcement'];
    if (encountered is! bool || needsReinforcement is! bool) {
      return const VocabularyReviewState();
    }
    return VocabularyReviewState(
      encountered: encountered,
      needsReinforcement: needsReinforcement,
    );
  }

  Future<void> markKnown(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  ) => _writeState(
    courseId,
    lessonId,
    entry,
    const VocabularyReviewState(encountered: true),
  );

  Future<void> requestReinforcement(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  ) => _writeState(
    courseId,
    lessonId,
    entry,
    const VocabularyReviewState(encountered: true, needsReinforcement: true),
  );

  Future<void> keepReinforcement(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  ) => requestReinforcement(courseId, lessonId, entry);

  Future<void> resetCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _storageKey(courseId));
  }

  Future<void> _writeState(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
    VocabularyReviewState state,
  ) async {
    final document = await _readDocument(courseId);
    final rawLessons = document['lessons'];
    final lessons = rawLessons is Map
        ? Map<String, dynamic>.from(rawLessons)
        : <String, dynamic>{};
    final rawLesson = lessons[lessonId];
    final lesson = rawLesson is Map
        ? Map<String, dynamic>.from(rawLesson)
        : <String, dynamic>{};
    lesson[entry.identity] = <String, dynamic>{
      'fingerprint': entry.fingerprint,
      'encountered': state.encountered,
      'needsReinforcement': state.needsReinforcement,
    };
    lessons[lessonId] = lesson;
    final encoded = jsonEncode(<String, dynamic>{
      'version': _storageVersion,
      'lessons': lessons,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _storageKey(courseId), encoded);
  }

  Future<Map<String, dynamic>> _readDocument(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _storageKey(courseId));
    if (raw == null) return _emptyDocument();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != _storageVersion) {
        return _emptyDocument();
      }
      final lessons = decoded['lessons'];
      if (lessons is! Map) return _emptyDocument();
      return <String, dynamic>{
        'version': _storageVersion,
        'lessons': Map<String, dynamic>.from(lessons),
      };
    } catch (_) {
      return _emptyDocument();
    }
  }

  Map<String, dynamic> _emptyDocument() => <String, dynamic>{
    'version': _storageVersion,
    'lessons': <String, dynamic>{},
  };

  Future<String> _storageKey(String courseId) =>
      _profiles.key('v1_vocabulary_review_course_${_digest(courseId.trim())}');

  static _VocabularyPair? _parsePair(String raw) {
    final line = raw.trim();
    for (final separator in _separators) {
      final at = line.indexOf(separator);
      if (at < 1) continue;
      final prompt = line.substring(0, at).trim();
      final answer = line.substring(at + separator.length).trim();
      if (prompt.isNotEmpty && answer.isNotEmpty) {
        return _VocabularyPair(prompt, answer);
      }
    }
    return null;
  }

  static String _contentIdentity(
    String id,
    Map<String, int> counts,
    Map<String, int> occurrences,
  ) {
    final occurrence = occurrences.update(
      id,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    return counts[id] == 1 ? 'id:$id' : 'id:$id#$occurrence';
  }

  static String _fallbackIdentity(
    String fingerprint,
    Map<String, int> occurrences,
  ) {
    final occurrence = occurrences.update(
      fingerprint,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    return 'fingerprint:$fingerprint#$occurrence';
  }

  static String _digest(String value) =>
      sha256.convert(utf8.encode(value)).toString().toLowerCase();
}

class _VocabularyPair {
  const _VocabularyPair(this.prompt, this.answer);

  final String prompt;
  final String answer;
}

class _ParsedVocabulary {
  const _ParsedVocabulary({
    required this.contentId,
    required this.fingerprint,
    required this.prompt,
    required this.answer,
  });

  final String contentId;
  final String fingerprint;
  final String prompt;
  final String answer;
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
