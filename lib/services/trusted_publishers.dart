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
  factory TrustedPublishers.application() => TrustedPublishers([
    // Production keys: none approved yet. Do not add test keys here.
    if (dummyEnabled) dummy,
  ]);

  TrustedPublisherKey? find(String publisherId, String keyId) {
    final matches = keys.where(
      (key) => key.publisherId == publisherId && key.keyId == keyId,
    );
    return matches.length == 1 ? matches.single : null;
  }
}
