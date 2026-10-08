import 'dart:convert';

/// Only keys explicitly approved by the QQL owner belong in the normal registry.
class TrustedPublisherKey {
  const TrustedPublisherKey({
    required this.publisherId,
    required this.publisherName,
    required this.keyId,
    required this.publicKeyBase64,
    this.revoked = false,
  });
  final String publisherId;
  final String publisherName;
  final String keyId;
  final String publicKeyBase64;
  final bool revoked;
  List<int> get publicKeyBytes => base64Decode(publicKeyBase64);
}

class TrustedPublishers {
  TrustedPublishers(Iterable<TrustedPublisherKey> keys)
    : keys = List.unmodifiable(keys);
  final List<TrustedPublisherKey> keys;
  static const dummyEnabled = bool.fromEnvironment(
    'QQL_ENABLE_DUMMY_PUBLISHER',
  );
  static const dummy = TrustedPublisherKey(
    publisherId: 'org.quisquislingo.test.dummy',
    publisherName: 'Dummy Publisher — TEST ONLY',
    keyId: 'dummy-1',
    publicKeyBase64: 'gSmelpGZaX9VzzJY6IkKGheBAtn56oVtwH7I7mwLgMs=',
  );

  /// QuisquisLingo Courses, the publisher of the owner's own Courses
  /// (`docs/PUBLISHER_COURSES_PLAN.md` 4.2, Build 262 Revision 1): a
  /// publisher separate from the app, approved like any other
  /// (`docs/PUBLISHER_SIGNING_GUIDE.md` §§3–6).
  ///
  /// Its key is pending: the owner creates it on their own computer (guide
  /// §2) and puts here the Base64 of its 32 public-key bytes (guide §6).
  /// While this is empty the app trusts no key for this publisher.
  static const quisquisLingoCoursesPublicKeyBase64 = '';
  static const quisquisLingoCourses = TrustedPublisherKey(
    publisherId: 'com.quisquislingo',
    publisherName: 'QuisquisLingo Courses',
    keyId: 'qqlc-2026-1',
    publicKeyBase64: quisquisLingoCoursesPublicKeyBase64,
  );

  factory TrustedPublishers.application() => TrustedPublishers([
    // Production keys: only approved ones. Do not add test keys here.
    if (quisquisLingoCoursesPublicKeyBase64.isNotEmpty) quisquisLingoCourses,
    if (dummyEnabled) dummy,
  ]);

  TrustedPublisherKey? find(String publisherId, String keyId) {
    final matches = keys.where(
      (key) => key.publisherId == publisherId && key.keyId == keyId,
    );
    return matches.length == 1 ? matches.single : null;
  }
}
