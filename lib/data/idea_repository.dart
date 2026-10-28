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

  /// Encrypted attachment bytes, keyed by [Attachment.id].
  Future<void> putFile(String id, Uint8List bytes);
  Future<Uint8List?> readFile(String id);
  Future<void> deleteFile(String id);

  /// Removes all ideas and attachments.
  Future<void> clear();
}

class InMemoryIdeaRepository implements IdeaRepository {
  InMemoryIdeaRepository([Iterable<Idea> seed = const []]) {
    for (final i in seed) {
      _items[i.id] = i;
    }
  }

  final Map<String, Idea> _items = {};
  final Map<String, Uint8List> files = {};

  @override
  Future<List<Idea>> loadAll() async => _items.values.toList();

  @override
  Future<void> put(Idea idea) async => _items[idea.id] = idea;

  @override
  Future<void> delete(String id) async => _items.remove(id);

  @override
  Future<void> putFile(String id, Uint8List bytes) async => files[id] = bytes;

  @override
  Future<Uint8List?> readFile(String id) async => files[id];

  @override
  Future<void> deleteFile(String id) async => files.remove(id);

  @override
  Future<void> clear() async {
    _items.clear();
    files.clear();
  }
}

/// AES-256 encrypted Hive boxes. Each idea is stored as a JSON string keyed by
/// id; attachment bytes go in a lazy box (read on demand, not held in memory)
/// encrypted with the same key. The 256-bit key lives in the iOS Keychain
/// (see [SecureKeyStore]).
class HiveIdeaRepository implements IdeaRepository {
  HiveIdeaRepository._(this._box, this._files);

  static const boxName = 'ideas_v1';
  static const filesBoxName = 'attachments_v1';
  final Box<String> _box;
  final LazyBox<Uint8List> _files;

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
    final files = await Hive.openLazyBox<Uint8List>(filesBoxName, encryptionCipher: HiveAesCipher(key));
    if (stored == null) await keyStore.writeKey(key);
    return HiveIdeaRepository._(box, files);
  }

  /// Irreversibly erases the store and its key.
  static Future<void> erase({required String directory, required KeyStore keyStore}) async {
    Hive.init(directory);
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.deleteBoxFromDisk(filesBoxName);
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
  Future<void> putFile(String id, Uint8List bytes) => _files.put(id, bytes);

  @override
  Future<Uint8List?> readFile(String id) => _files.get(id);

  @override
  Future<void> deleteFile(String id) async {
    await _files.delete(id);
    // Deleted bytes stay in the file until compaction; reclaim space promptly.
    await _files.compact();
  }

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
    await _files.clear();
    await _files.compact();
  }
}
