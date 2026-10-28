import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Supplies the 256-bit database encryption key and small secure settings.
abstract interface class KeyStore {
  /// The stored 32-byte key, or null when missing or unreadable.
  Future<List<int>?> readKey();
  Future<void> writeKey(List<int> key);
  Future<void> deleteKey();
  Future<bool> readFlag(String name);
  Future<void> writeFlag(String name, {required bool value});
}

List<int> generateKey([Random? rng]) {
  final r = rng ?? Random.secure();
  return List<int>.generate(32, (_) => r.nextInt(256));
}

/// iOS Keychain backed store. `first_unlock_this_device` keeps the key out of
/// iCloud Keychain and device-to-device backups.
class SecureKeyStore implements KeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _keyName = 'brainstash.db.key.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<int>?> readKey() async {
    try {
      final existing = await _storage.read(key: _keyName);
      if (existing == null) return null;
      final bytes = base64Decode(existing);
      return bytes.length == 32 ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeKey(List<int> key) =>
      _storage.write(key: _keyName, value: base64Encode(key));

  @override
  Future<void> deleteKey() => _storage.delete(key: _keyName);

  @override
  Future<bool> readFlag(String name) async =>
      (await _storage.read(key: 'flag.$name')) == 'true';

  @override
  Future<void> writeFlag(String name, {required bool value}) =>
      _storage.write(key: 'flag.$name', value: value.toString());
}

class InMemoryKeyStore implements KeyStore {
  List<int>? _key;
  final Map<String, bool> _flags = {};

  @override
  Future<List<int>?> readKey() async => _key;

  @override
  Future<void> writeKey(List<int> key) async => _key = key;

  @override
  Future<void> deleteKey() async => _key = null;

  @override
  Future<bool> readFlag(String name) async => _flags[name] ?? false;

  @override
  Future<void> writeFlag(String name, {required bool value}) async =>
      _flags[name] = value;
}
