import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

const _creatorId = '11111111-1111-4111-8111-111111111111';
const _maintainerId = '22222222-2222-4222-8222-222222222222';
const _editorId = '33333333-3333-4333-8333-333333333333';

Course _course({CourseForkProvenance? forkProvenance}) => Course(
  courseId: 'course-v9',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _creatorId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_maintainerId),
  assignedTeamId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  originalCreatedAtUtc: '2026-09-01T08:00:00.000Z',
  lastVersionEditorProfileId: _editorId,
  lastVersionEditorDisplayName: 'Last Editor',
  modifiedAtUtc: '2026-09-12T09:30:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Clean metadata',
  ttsLanguage: 'it-IT',
  authors: const [
    CourseAuthor(name: 'Credited Author', roles: ['Author', 'Reviewer']),
  ],
  rightsHolders: const [
    CourseRightsHolder(
      type: CourseRightsHolderType.person,
      name: 'Rights Person',
    ),
    CourseRightsHolder(
      type: CourseRightsHolderType.organization,
      name: 'Rights Organisation',
    ),
  ],
  license: 'CC BY 4.0',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  forkProvenance: forkProvenance,
  courseVersion: '4',
  lessons: const [],
);

Course _officialCourse() => Course(
  courseId: 'official-v9',
  originType: CourseOriginType.bundledOfficial,
  publisherId: 'publisher.example',
  publisherName: 'Example Publisher',
  officialCourseVersion: '2026.09',
  officialReleaseDateUtc: '2026-09-01T08:00:00.000Z',
  officialChecksum: List<String>.filled(64, 'a').join(),
  distributionChannel: 'bundled',
  publisherVerificationStatus: PublisherVerificationStatus.verified,
  originalCourseCreator: const CourseProvenanceIdentity.publisher(
    publisherId: 'publisher.example',
    displayName: 'Example Publisher',
  ),
  originalCreatedAtUtc: '2026-09-01T08:00:00.000Z',
  modifiedAtUtc: '2026-09-01T08:00:00.000Z',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Official Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

void main() {
  test('Course Model v9 writes only authoritative metadata', () {
    final json = _course().toJson();

    expect(json['formatVersion'], 9);
    expect(json['originalCourseCreator'], {
      'type': 'qqlUser',
      'id': _creatorId,
      'displayName': 'Original Creator',
    });
    expect(json['maintainer'], {'profileId': _maintainerId});
    expect(json['originalCreatedAtUtc'], '2026-09-01T08:00:00.000Z');
    expect(json['lastVersionEditorProfileId'], _editorId);
    expect(json['lastVersionEditorDisplayName'], 'Last Editor');
    expect(json['modifiedAtUtc'], '2026-09-12T09:30:00.000Z');
    expect(json['rightsHolders'], [
      {'type': 'person', 'name': 'Rights Person'},
      {'type': 'organization', 'name': 'Rights Organisation'},
    ]);
    expect(json['authors'], [
      {
        'name': 'Credited Author',
        'roles': ['Author', 'Reviewer'],
      },
    ]);

    for (final removed in const [
      'creatorProfileId',
      'ownership',
      'createdByProfileId',
      'createdByUsername',
      'createdAtUtc',
      'lastModifiedByProfileId',
      'lastModifiedByUsername',
      'lastModifiedAtUtc',
      'lastUpdated',
      'author',
      'version',
      'updateSummary',
      'contentRevision',
      'parentCourseId',
      'derivedFromVersion',
    ]) {
      expect(json, isNot(contains(removed)), reason: removed);
    }

    final restored = Course.fromJson(json);
    expect(restored.originalCourseCreator.id, _creatorId);
    expect(restored.maintainer!.profileId, _maintainerId);
    expect(restored.originalCreatedAtUtc, '2026-09-01T08:00:00.000Z');
    expect(restored.lastVersionEditorProfileId, _editorId);
    expect(restored.modifiedAtUtc, '2026-09-12T09:30:00.000Z');
    expect(restored.rightsHolders, hasLength(2));
  });

  test('Course Model v9 rejects v8 and removed metadata aliases', () {
    final valid = _course().toJson();
    expect(
      () => Course.fromJson({...valid, 'formatVersion': 8}),
      throwsFormatException,
    );
    for (final removed in const [
      'creatorProfileId',
      'ownership',
      'createdByProfileId',
      'createdByUsername',
      'createdAtUtc',
      'lastModifiedByProfileId',
      'lastModifiedByUsername',
      'lastModifiedAtUtc',
      'lastUpdated',
      'author',
      'version',
      'updateSummary',
      'contentRevision',
      'parentCourseId',
      'derivedFromVersion',
    ]) {
      expect(
        () => Course.fromJson({...valid, removed: 'obsolete'}),
        throwsFormatException,
        reason: removed,
      );
    }
    expect(
      () => Course.fromJson({...valid, 'courseVersion': '4.1'}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson(
        Map<String, dynamic>.from(valid)..remove('originType'),
      ),
      throwsFormatException,
    );
    for (final malformed in const <String, Object>{
      'courseVersion': 4,
      'versionNotes': 4,
      'restoredFromVersion': '4',
    }.entries) {
      expect(
        () => Course.fromJson({...valid, malformed.key: malformed.value}),
        throwsFormatException,
        reason: malformed.key,
      );
    }
  });

  test('structured author roles reject the removed scalar role alias', () {
    expect(
      CourseAuthor.fromJson({
        'name': 'Author',
        'roles': ['Author'],
      }).roles,
      ['Author'],
    );
    expect(
      () => CourseAuthor.fromJson({
        'name': 'Author',
        'role': 'Author',
        'roles': ['Author'],
      }),
      throwsFormatException,
    );
  });

  test('custom and official version metadata remain origin-specific', () {
    final custom = _course().toJson();
    for (final field in const <String, Object>{
      'publisherId': 'publisher.example',
      'publisherName': 'Example Publisher',
      'officialCourseVersion': '2026.09',
      'officialReleaseDateUtc': '2026-09-01T08:00:00.000Z',
      'officialChecksum':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'officialReleaseNotes': 'Publisher notes',
      'distributionChannel': 'bundled',
      'publisherVerificationStatus': 'verified',
      'publisherSignature': 'signature',
    }.entries) {
      expect(
        () => Course.fromJson({...custom, field.key: field.value}),
        throwsFormatException,
        reason: field.key,
      );
    }

    final official = _officialCourse().toJson();
    for (final field in const <String, Object>{
      'courseVersion': '1',
      'versionNotes': 'Local edit',
      'restoredFromVersion': 1,
    }.entries) {
      expect(
        () => Course.fromJson({...official, field.key: field.value}),
        throwsFormatException,
        reason: field.key,
      );
    }
  });

  test('fork provenance uses immediate source and no scalar author alias', () {
    final provenance = CourseForkProvenance(
      sourceCourseId: 'source-course',
      sourceCourseTitle: 'Source Course',
      sourceCourseVersion: '3',
      sourceOriginType: CourseOriginType.custom,
      sourceAuthors: [
        CourseAuthor(name: 'Source Author', roles: ['Author']),
      ],
      forkCreatedByProfileId: _maintainerId,
      forkCreatedByDisplayName: 'Fork Creator',
      forkCreatedAtUtc: '2026-09-12T09:00:00.000Z',
    );

    final json = _course(forkProvenance: provenance).toJson();
    final forkJson = json['forkProvenance'] as Map<String, dynamic>;
    expect(forkJson['sourceCourseId'], 'source-course');
    expect(forkJson['forkCreatedByProfileId'], _maintainerId);
    expect(forkJson, isNot(contains('originalAuthor')));
    expect(forkJson, isNot(contains('originalAuthors')));
    expect(
      Course.fromJson(json).forkProvenance!.sourceCourseId,
      'source-course',
    );
  });
}
