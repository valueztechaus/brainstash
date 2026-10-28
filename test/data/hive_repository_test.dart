import 'dart:io';

import 'package:brainstash/data/idea_repository.dart';
import 'package:brainstash/data/key_store.dart';
import 'package:brainstash/models/idea.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('brainstash_test'));
  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('should persist ideas and encrypt them on disk', () async {
    final keys = InMemoryKeyStore();
    final repo = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    final idea = Idea.create(title: 'TOPSECRETIDEA', notes: 'PLAINTEXTNOTES');
    await repo.put(idea);
    await Hive.close();

    final bytes = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hive'))
        .expand((f) => f.readAsBytesSync())
        .toList();
    final asText = String.fromCharCodes(bytes);
    expect(asText.contains('TOPSECRETIDEA'), isFalse);
    expect(asText.contains('PLAINTEXTNOTES'), isFalse);

    final reopened = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    expect((await reopened.loadAll()).single, idea);
  });

  test('should delete and clear', () async {
    final repo = await HiveIdeaRepository.open(
      directory: dir.path,
      keyStore: InMemoryKeyStore(),
    );
    final a = Idea.create(title: 'a');
    final b = Idea.create(title: 'b');
    await repo.put(a);
    await repo.put(b);
    await repo.delete(a.id);
    expect((await repo.loadAll()).single.id, b.id);
    await repo.clear();
    expect(await repo.loadAll(), isEmpty);
  });

  test('should refuse to silently replace a lost key when data exists', () async {
    final keys = InMemoryKeyStore();
    final repo = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    await repo.put(Idea.create(title: 'precious'));
    await Hive.close();
    await keys.deleteKey();
    await expectLater(
      HiveIdeaRepository.open(directory: dir.path, keyStore: keys),
      throwsA(isA<StoreKeyLostError>()),
    );
    expect(await keys.readKey(), isNull, reason: 'no new key written');
  });

  test('erase should allow a fresh start after key loss', () async {
    final keys = InMemoryKeyStore();
    final repo = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    await repo.put(Idea.create(title: 'gone'));
    await Hive.close();
    await keys.deleteKey();
    await HiveIdeaRepository.erase(directory: dir.path, keyStore: keys);
    final fresh = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    expect(await fresh.loadAll(), isEmpty);
    expect(await keys.readKey(), hasLength(32));
  });

  test('generateKey should return 32 bytes', () {
    expect(generateKey(), hasLength(32));
  });
}
