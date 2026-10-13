import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_media_reference.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_service.dart';

/// Build 272 Revision 8: how a Course names its own pictures and recordings
/// (`media:<sha256>.<ext>`). The first two groups were written before the
/// rule got one owner and are unchanged by it.
const _hash =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

/// One reference and what each entry point says about it:
/// picture a Course may name, recording a Course may name, cover (a
/// Course-owned picture), any Course media, Story avatar.
typedef _Row = ({
  String value,
  bool image,
  bool audio,
  bool cover,
  bool media,
  bool avatar,
});

const List<_Row> _rows = [
  (
    value: '',
    image: true,
    audio: true,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'media:$_hash.png',
    image: true,
    audio: false,
    cover: true,
    media: true,
    avatar: true,
  ),
  (
    value: 'media:$_hash.jpg',
    image: true,
    audio: false,
    cover: true,
    media: true,
    avatar: true,
  ),
  (
    value: 'media:$_hash.jpeg',
    image: true,
    audio: false,
    cover: true,
    media: true,
    avatar: true,
  ),
  (
    value: 'media:$_hash.webp',
    image: true,
    audio: false,
    cover: true,
    media: true,
    avatar: true,
  ),
  (
    value: 'media:$_hash.mp3',
    image: false,
    audio: true,
    cover: false,
    media: true,
    avatar: false,
  ),
  // Another kind of file, a short or capital hash, a capital extension, a
  // space, a prefix: none is a Course's media.
  (
    value: 'media:$_hash.gif',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'media:0123456789abcdef.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value:
        'media:0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'media:$_hash.PNG',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'media:$_hash.png ',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'xmedia:$_hash.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'media/$_hash.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  // QQL's own files, an embedded picture, paths of one device.
  (
    value: 'assets/exercise_images/apple.webp',
    image: true,
    audio: true,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'assets/avatars/cat.png',
    image: true,
    audio: true,
    cover: false,
    media: false,
    avatar: true,
  ),
  (
    value: 'assets/../secret.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'data:image/png;base64,AAAA',
    image: true,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: r'C:\Users\me\picture.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: '/home/me/recording.mp3',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
  (
    value: 'file:///home/me/picture.png',
    image: false,
    audio: false,
    cover: false,
    media: false,
    avatar: false,
  ),
];

Map<String, dynamic> _copy(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

/// The first map under [node] that [test] accepts, depth first.
Map<String, dynamic>? _find(
  Object? node,
  bool Function(Map<String, dynamic>) test,
) {
  if (node is Map<String, dynamic>) {
    if (test(node)) return node;
    for (final value in node.values) {
      final found = _find(value, test);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _find(value, test);
      if (found != null) return found;
    }
  }
  return null;
}

Matcher _refuses(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', message),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what counts as a reference, at every entry point', () {
    for (final row in _rows) {
      test('"${row.value}"', () {
        expect(Course.isValidImageReference(row.value), row.image);
        expect(Course.isValidAudioReference(row.value), row.audio);
        expect(Course.coverImagePattern.hasMatch(row.value), row.cover);
        expect(CourseMediaStore.isReference(row.value), row.media);
        expect(
          CourseMediaStore.isImageReference(row.value),
          row.media && row.cover,
        );
        expect(
          CourseMediaStore.isAudioReference(row.value),
          row.media && row.audio,
        );
        expect(StorySpeaker.avatarPattern.hasMatch(row.value), row.avatar);
      });
    }

    test('the parts of a reference', () {
      const reference = 'media:$_hash.webp';
      expect(CourseMediaStore.digestOf(reference), _hash);
      expect(CourseMediaStore.extensionOf(reference), 'webp');
      expect(CourseMediaStore.fileNameOf(reference), '$_hash.webp');
    });
  });

  group('CourseMediaReference, the one owner of the rule', () {
    test('its patterns are, letter for letter, the ones written before', () {
      expect(
        CourseMediaReference.image.pattern,
        r'^media:[0-9a-f]{64}\.(png|jpg|jpeg|webp)$',
      );
      expect(CourseMediaReference.audio.pattern, r'^media:[0-9a-f]{64}\.mp3$');
      expect(
        CourseMediaReference.any.pattern,
        r'^media:([0-9a-f]{64})\.(mp3|png|jpg|jpeg|webp)$',
      );
      expect(
        CourseMediaReference.fileName.pattern,
        r'^[0-9a-f]{64}\.(mp3|png|jpg|jpeg|webp)$',
      );
      expect(
        CourseMediaReference.packagePath.pattern,
        r'^media/([0-9a-f]{64})\.(mp3|png|jpg|jpeg|webp)$',
      );
      expect(
        StorySpeaker.avatarPattern.pattern,
        r'^(assets/avatars/[a-z0-9_]+\.png|media:[0-9a-f]{64}\.(png|jpg|jpeg|webp))$',
      );
    });

    test('the model and the media store read it, they keep no copy', () {
      expect(Course.coverImagePattern, same(CourseMediaReference.image));
      expect(CourseMediaStore.referencePattern, same(CourseMediaReference.any));
      expect(
        CourseMediaStore.audioExtensions,
        same(CourseMediaReference.audioExtensions),
      );
      expect(
        CourseMediaStore.imageExtensions,
        same(CourseMediaReference.imageExtensions),
      );
    });

    test('the kinds of file are the ones the patterns name', () {
      final images = CourseMediaReference.imageExtensions.join('|');
      final all = [
        ...CourseMediaReference.audioExtensions,
        ...CourseMediaReference.imageExtensions,
      ].join('|');
      expect(CourseMediaReference.image.pattern, endsWith('\\.($images)\$'));
      expect(CourseMediaReference.any.pattern, endsWith('\\.($all)\$'));
      expect(CourseMediaReference.fileName.pattern, endsWith('\\.($all)\$'));
      expect(CourseMediaReference.packagePath.pattern, endsWith('\\.($all)\$'));
      expect(
        CourseMediaReference.audio.pattern,
        endsWith('\\.${CourseMediaReference.audioExtensions.single}\$'),
      );
    });

    for (final row in _rows) {
      test('"${row.value}"', () {
        expect(CourseMediaReference.isValidImage(row.value), row.image);
        expect(CourseMediaReference.isValidAudio(row.value), row.audio);
        expect(CourseMediaReference.isImage(row.value), row.cover);
        expect(CourseMediaReference.isAny(row.value), row.media);
        expect(CourseMediaReference.isAudio(row.value), row.media && row.audio);
      });
    }

    test('the stored file\'s name and its path in a package', () {
      expect(CourseMediaReference.fileName.hasMatch('$_hash.mp3'), isTrue);
      expect(CourseMediaReference.fileName.hasMatch('$_hash.gif'), isFalse);
      expect(
        CourseMediaReference.fileName.hasMatch('media:$_hash.mp3'),
        isFalse,
      );
      final match = CourseMediaReference.packagePath.firstMatch(
        'media/$_hash.webp',
      )!;
      expect(match.group(1), _hash);
      expect(match.group(2), 'webp');
      expect(
        CourseMediaReference.packagePath.hasMatch('media/../$_hash.webp'),
        isFalse,
      );
      expect(
        CourseMediaReference.packagePath.hasMatch('media:$_hash.webp'),
        isFalse,
      );
    });

    test('the walk of a Course file refuses the same three things, with the '
        'same words', () {
      expect(
        () => CourseMediaReference.checkCourseJson({
          'audioLibrary': [
            {'filePath': r'C:\rec\ciao.mp3'},
          ],
        }),
        _refuses(
          r'Audio Library recording "C:\rec\ciao.mp3" is not supported. '
          'Recordings must be bundled assets or course media '
          '(media:<sha256>.mp3), never a path on one device.',
        ),
      );
      expect(
        () => CourseMediaReference.checkCourseJson({
          'lessons': [
            {
              'deep': [
                {'type': 'image', 'asset': 'file:///a.png'},
              ],
            },
          ],
        }),
        _refuses(
          'Exercise image "file:///a.png" is not supported. Images must be '
          'bundled assets, embedded images or course media '
          '(media:<sha256>.<png|jpg|jpeg|webp>), never a path on one device.',
        ),
      );
      expect(
        () => CourseMediaReference.checkCourseJson({
          'lessons': [
            {'role': 'icon', 'text': 'assets/.hidden/x.png'},
          ],
        }),
        _refuses('Picture key "assets/.hidden/x.png" is not a QQL picture.'),
      );
      // Nothing to refuse: an empty file, bundled files, Course media, an
      // image element outside the Lessons (the cover has its own check).
      CourseMediaReference.checkCourseJson({});
      CourseMediaReference.checkCourseJson({
        'audioLibrary': [
          {'filePath': 'media:$_hash.mp3'},
          {'filePath': 'assets/audio/ciao.mp3'},
          {'filePath': 7},
        ],
        'cover': {'type': 'image', 'asset': '/home/me/a.png'},
        'lessons': [
          {'type': 'image', 'asset': 'media:$_hash.png'},
          {'type': 'image', 'asset': 'data:image/png;base64,AAAA'},
          {'type': 'text', 'asset': '/home/me/a.png'},
          {'role': 'icon', 'text': 'assets/exercise_images/apple.webp'},
          {'role': 'icon', 'text': 'cat'},
        ],
      });
    });
  });

  group('a Course file that names media no other device has is refused', () {
    late Map<String, dynamic> laboratory;

    setUpAll(() async {
      laboratory = (await CourseService().loadBundledCourse('IT')).toJson();
      // The file as it is reads back.
      expect(
        Course.fromJson(_copy(laboratory)).courseId,
        laboratory['courseId'],
      );
    });

    test('a recording by its path', () {
      final json = _copy(laboratory)
        ..['audioLibrary'] = [
          {'id': 'clip-1', 'text': 'ciao', 'filePath': '/home/me/ciao.mp3'},
        ];
      expect(
        () => Course.fromJson(json),
        _refuses(
          'Audio Library recording "/home/me/ciao.mp3" is not supported. '
          'Recordings must be bundled assets or course media '
          '(media:<sha256>.mp3), never a path on one device.',
        ),
      );
      json['audioLibrary'] = [
        {'id': 'clip-1', 'text': 'ciao', 'filePath': 'media:$_hash.mp3'},
      ];
      expect(
        Course.fromJson(json).audioLibrary.single.filePath,
        'media:$_hash.mp3',
      );
    });

    test('a picture by its path, the long ones cut at 120 characters', () {
      final json = _copy(laboratory);
      final image = _find(
        json['lessons'],
        (map) => map['type'] == 'image' && map['asset'] is String,
      )!;
      image['asset'] = '/home/me/picture.png';
      expect(
        () => Course.fromJson(json),
        _refuses(
          'Exercise image "/home/me/picture.png" is not supported. Images '
          'must be bundled assets, embedded images or course media '
          '(media:<sha256>.<png|jpg|jpeg|webp>), never a path on one device.',
        ),
      );
      final long = '/home/me/${'a' * 200}.png';
      image['asset'] = long;
      expect(
        () => Course.fromJson(json),
        _refuses(
          'Exercise image "${long.substring(0, 120)}…" is not supported. '
          'Images must be bundled assets, embedded images or course media '
          '(media:<sha256>.<png|jpg|jpeg|webp>), never a path on one device.',
        ),
      );
    });

    test('a picture key outside QQL\'s own files', () {
      final json = _copy(laboratory);
      final icon = _find(
        json['lessons'],
        (map) =>
            map['role'] == 'icon' &&
            map['text'] is String &&
            (map['text'] as String).startsWith('assets/'),
      )!;
      icon['text'] = 'assets/../secret.png';
      expect(
        () => Course.fromJson(json),
        _refuses('Picture key "assets/../secret.png" is not a QQL picture.'),
      );
    });

    test('a cover that is not a Course picture', () {
      final json = _copy(laboratory)..['coverImage'] = 'media:$_hash.gif';
      expect(
        () => Course.fromJson(json),
        _refuses(
          'course.coverImage must be a media:<sha256>.<png|jpg|jpeg|webp> reference.',
        ),
      );
    });

    test('an image library entry that is not a Course picture', () {
      final json = _copy(laboratory)
        ..['imageLibrary'] = [
          {'asset': 'assets/exercise_images/apple.webp'},
        ];
      expect(
        () => Course.fromJson(json),
        _refuses(
          'imageLibrary entries must be media:<sha256>.<png|jpg|jpeg|webp> images.',
        ),
      );
    });

    test(
      'a Story avatar that is neither a QQL avatar nor a Course picture',
      () {
        final json = _copy(laboratory);
        final characters = json['storyCharacters'] as List;
        (characters.first as Map<String, dynamic>)['avatar'] =
            'assets/mascots/cat.png';
        expect(
          () => Course.fromJson(json),
          _refuses(
            'story avatar “assets/mascots/cat.png” must be '
            'assets/avatars/<name>.png or a Course-owned media image.',
          ),
        );
      },
    );

    test('a shared image source on a picture the Course does not own', () {
      final json = _copy(laboratory);
      final image = _find(
        json['lessons'],
        (map) =>
            map['type'] == 'image' &&
            map['asset'] is String &&
            (map['asset'] as String).startsWith('assets/'),
      )!;
      image['sharedImageSource'] = <String, dynamic>{};
      expect(
        () => Course.fromJson(json),
        _refuses('sharedImageSource requires a Course-owned image.'),
      );
    });
  });
}
