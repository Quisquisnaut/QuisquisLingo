import 'course_models.dart';
import 'world_flag_entity.dart';

enum CourseFlagSelectionKind { automatic, builtIn, worldFlag, customImage }

/// A self-contained Course flag value.
///
/// It deliberately carries no source-Course identity. Applying a selection
/// writes only the existing Course Model v11 flag fields.
class CourseFlagSelection {
  final CourseFlagSelectionKind kind;
  final String builtInCode;
  final String worldFlagId;
  final String customImageBase64;

  const CourseFlagSelection._({
    required this.kind,
    this.builtInCode = '',
    this.worldFlagId = '',
    this.customImageBase64 = '',
  });

  const CourseFlagSelection.automatic()
    : this._(kind: CourseFlagSelectionKind.automatic);

  factory CourseFlagSelection.builtIn(String code) => CourseFlagSelection._(
    kind: CourseFlagSelectionKind.builtIn,
    builtInCode: code.trim().toUpperCase(),
  );

  factory CourseFlagSelection.worldFlag(String id) => CourseFlagSelection._(
    kind: CourseFlagSelectionKind.worldFlag,
    worldFlagId: id.trim(),
  );

  factory CourseFlagSelection.customImage(String base64Png) =>
      CourseFlagSelection._(
        kind: CourseFlagSelectionKind.customImage,
        customImageBase64: base64Png.trim(),
      );

  factory CourseFlagSelection.fromCourse(Course course) {
    if (course.worldFlagId.trim().isNotEmpty) {
      return CourseFlagSelection.worldFlag(course.worldFlagId);
    }
    if (course.flagImageBase64.trim().isNotEmpty) {
      return CourseFlagSelection.customImage(course.flagImageBase64);
    }
    if (course.flagCode.trim().isNotEmpty) {
      return CourseFlagSelection.builtIn(course.flagCode);
    }
    return const CourseFlagSelection.automatic();
  }

  String get flagCode =>
      kind == CourseFlagSelectionKind.builtIn ? builtInCode : '';

  String get flagImageBase64 =>
      kind == CourseFlagSelectionKind.customImage ? customImageBase64 : '';

  String get selectedWorldFlagId =>
      kind == CourseFlagSelectionKind.worldFlag ? worldFlagId : '';

  String get stableKey => switch (kind) {
    CourseFlagSelectionKind.automatic => 'automatic',
    CourseFlagSelectionKind.builtIn => 'builtin:$builtInCode',
    CourseFlagSelectionKind.worldFlag => 'world:$worldFlagId',
    CourseFlagSelectionKind.customImage => 'custom-image',
  };

  Map<String, dynamic> applyToJson(Map<String, dynamic> courseJson) => {
    ...courseJson,
    'flagCode': flagCode,
    'flagImageBase64': flagImageBase64,
    'worldFlagId': selectedWorldFlagId,
  };

  @override
  bool operator ==(Object other) =>
      other is CourseFlagSelection &&
      other.kind == kind &&
      other.builtInCode == builtInCode &&
      other.worldFlagId == worldFlagId &&
      other.customImageBase64 == customImageBase64;

  @override
  int get hashCode =>
      Object.hash(kind, builtInCode, worldFlagId, customImageBase64);
}

enum CourseFlagCatalogSectionKind { qqlFlagPainter, worldFlags }

class CourseFlagCandidate {
  final String identity;
  final CourseFlagSelection selection;
  final String label;
  final String subtitle;
  final List<String> searchTerms;
  final WorldFlagEntity? worldFlag;

  const CourseFlagCandidate({
    required this.identity,
    required this.selection,
    required this.label,
    required this.subtitle,
    required this.searchTerms,
    this.worldFlag,
  });

  bool matchesDirectly(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final values = <String>[
      identity,
      label,
      subtitle,
      ...searchTerms,
    ].map((value) => value.trim().toLowerCase()).toList(growable: false);
    final haystack = values.join('\n');
    return normalized
        .split(RegExp(r'\s+'))
        .every((token) => haystack.contains(token));
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (matchesDirectly(normalized)) return true;

    // Suggestions are keyed by a stable base language tag (for example
    // `nap`), while authored Course metadata may use a regional BCP-47 tag
    // such as `nap-IT`. Match that explicit base tag, but do not broaden a
    // subdivision query such as `GB-WLS` to every `GB-*` flag.
    final normalizedTag = normalized.replaceAll('_', '-');
    if (!RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})+$').hasMatch(normalizedTag)) {
      return false;
    }
    final baseTag = normalizedTag.split('-').first;
    return searchTerms.any((term) {
      final candidateTag = term.trim().toLowerCase().replaceAll('_', '-');
      return candidateTag == baseTag;
    });
  }

  CourseFlagCandidate copyWith({String? subtitle, List<String>? searchTerms}) =>
      CourseFlagCandidate(
        identity: identity,
        selection: selection,
        label: label,
        subtitle: subtitle ?? this.subtitle,
        searchTerms: searchTerms ?? this.searchTerms,
        worldFlag: worldFlag,
      );
}

class CourseFlagCatalogSection {
  final CourseFlagCatalogSectionKind kind;
  final String title;
  final List<CourseFlagCandidate> candidates;

  const CourseFlagCatalogSection({
    required this.kind,
    required this.title,
    required this.candidates,
  });
}

class CourseFlagCatalog {
  final List<CourseFlagCatalogSection> sections;
  final CourseFlagCandidate? automaticCandidate;
  final CourseFlagCandidate? suggestedWorldFlag;
  final String automaticUnavailableMessage;
  final String worldSuggestionUnavailableMessage;

  const CourseFlagCatalog({
    required this.sections,
    this.automaticCandidate,
    this.suggestedWorldFlag,
    this.automaticUnavailableMessage = '',
    this.worldSuggestionUnavailableMessage = '',
  });

  List<CourseFlagCatalogSection> search(String query) {
    final normalized = query.trim();
    final hasDirectMatch =
        normalized.isNotEmpty &&
        candidates.any((candidate) => candidate.matchesDirectly(normalized));
    return List.unmodifiable(
      sections
          .map(
            (section) => CourseFlagCatalogSection(
              kind: section.kind,
              title: section.title,
              candidates: List.unmodifiable(
                section.candidates.where(
                  (candidate) => hasDirectMatch
                      ? candidate.matchesDirectly(normalized)
                      : candidate.matches(normalized),
                ),
              ),
            ),
          )
          .where((section) => section.candidates.isNotEmpty),
    );
  }

  Iterable<CourseFlagCandidate> get candidates sync* {
    for (final section in sections) {
      yield* section.candidates;
    }
  }
}
