import 'dart:io';
import 'dart:typed_data';

import 'package:brainstash/data/idea_repository.dart';
import 'package:brainstash/data/key_store.dart';
import 'package:brainstash/models/attachment.dart';
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

  test('should store attachment bytes encrypted and erase them', () async {
    final keys = InMemoryKeyStore();
    final repo = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    final secret = Uint8List.fromList('PLAINTEXTATTACHMENT'.codeUnits);
    await repo.putFile('f1', secret);
    expect(await repo.readFile('f1'), secret);
    await Hive.close();

    final onDisk = String.fromCharCodes(dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.hive'))
        .expand((f) => f.readAsBytesSync()));
    expect(onDisk.contains('PLAINTEXTATTACHMENT'), isFalse);

    final reopened = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    expect(await reopened.readFile('f1'), secret);
    await reopened.deleteFile('f1');
    expect(await reopened.readFile('f1'), isNull);
    await reopened.putFile('f2', secret);
    await reopened.clear();
    expect(await reopened.readFile('f2'), isNull);
    await Hive.close();

    await HiveIdeaRepository.erase(directory: dir.path, keyStore: keys);
    expect(dir.listSync().whereType<File>().where((f) => f.path.endsWith('.hive')), isEmpty);
  });

  test('should hold a maximum-size attachment', () async {
    final keys = InMemoryKeyStore();
    final repo = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    final big = Uint8List(Attachment.maxBytes)..fillRange(0, 1000, 9);
    await repo.putFile('big', big);
    await Hive.close();
    final reopened = await HiveIdeaRepository.open(directory: dir.path, keyStore: keys);
    final back = await reopened.readFile('big');
    expect(back!.length, Attachment.maxBytes);
    expect(back.sublist(0, 1000).every((b) => b == 9), isTrue);
  });
}
