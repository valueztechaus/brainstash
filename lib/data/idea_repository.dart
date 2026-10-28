import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/idea.dart';
import 'key_store.dart';

class StoreKeyLostError implements Exception {
  const StoreKeyLostError();
}

/// Persistence boundary for ideas. UI and state never touch storage directly.
abstract interface class IdeaRepository {
  Future<List<Idea>> loadAll();
  Future<void> put(Idea idea);
  Future<void> delete(String id);
  Future<void> clear();
}

class InMemoryIdeaRepository implements IdeaRepository {
  InMemoryIdeaRepository([Iterable<Idea> seed = const []]) {
    for (final i in seed) {
      _items[i.id] = i;
    }
  }

  final Map<String, Idea> _items = {};

  @override
  Future<List<Idea>> loadAll() async => _items.values.toList();

  @override
  Future<void> put(Idea idea) async => _items[idea.id] = idea;

  @override
  Future<void> delete(String id) async => _items.remove(id);

  @override
  Future<void> clear() async => _items.clear();
}

/// AES-256 encrypted Hive box. Each idea is stored as a JSON string keyed by id.
/// The 256-bit key lives in the iOS Keychain (see [SecureKeyStore]).
class HiveIdeaRepository implements IdeaRepository {
  HiveIdeaRepository._(this._box);

  static const boxName = 'ideas_v1';
  final Box<String> _box;

  /// Opens the store. A new key is created only when no store exists yet; if a
  /// store exists but its key is gone (e.g. Keychain reset), throws
  /// [StoreKeyLostError] instead of silently orphaning the data.
  static Future<HiveIdeaRepository> open({
    required String directory,
    required KeyStore keyStore,
  }) async {
    Hive.init(directory);
    final exists = await Hive.boxExists(boxName);
    final stored = await keyStore.readKey();
    if (stored == null && exists) throw const StoreKeyLostError();
    final key = stored ?? generateKey();
    final box = await Hive.openBox<String>(boxName, encryptionCipher: HiveAesCipher(key));
    if (stored == null) await keyStore.writeKey(key);
    return HiveIdeaRepository._(box);
  }

  /// Irreversibly erases the store and its key.
  static Future<void> erase({required String directory, required KeyStore keyStore}) async {
    Hive.init(directory);
    await Hive.deleteBoxFromDisk(boxName);
    await keyStore.deleteKey();
  }

  @override
  Future<List<Idea>> loadAll() async {
    final out = <Idea>[];
    var skipped = 0;
    for (final raw in _box.values) {
      try {
        out.add(Idea.fromMap(jsonDecode(raw) as Map<String, dynamic>));
      } on Object {
        // A corrupt record must not take the whole inbox down; skip it.
        skipped++;
      }
    }
    if (skipped > 0) debugPrint('Brainstash: skipped $skipped unreadable records');
    return out;
  }

  @override
  Future<void> put(Idea idea) => _box.put(idea.id, jsonEncode(idea.toMap()));

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }
}
