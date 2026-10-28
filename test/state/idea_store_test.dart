import 'dart:convert';
import 'dart:typed_data';

import 'package:brainstash/data/idea_repository.dart';
import 'package:brainstash/models/attachment.dart';
import 'package:brainstash/models/idea.dart';
import 'package:brainstash/state/idea_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepo extends InMemoryIdeaRepository {
  @override
  Future<List<Idea>> loadAll() async => throw StateError('keychain locked');
}

void main() {
  late InMemoryIdeaRepository repo;
  late IdeaStore store;

  setUp(() async {
    repo = InMemoryIdeaRepository([
      Idea.create(title: 'Job plan checker', kind: IdeaKind.product, tags: ['maximo']),
      Idea.create(title: 'Health review', kind: IdeaKind.service, notes: 'quarterly'),
      Idea.create(title: 'Lost field notes', kind: IdeaKind.problem),
    ]);
    store = IdeaStore(repo);
    await store.load();
  });

  test('should load all ideas', () {
    expect(store.loaded, isTrue);
    expect(store.total, 3);
    expect(store.countFor(IdeaKind.product), 1);
    expect(store.countFor(null), 3);
  });

  test('should filter by kind', () {
    store.setKindFilter(IdeaKind.service);
    expect(store.visible.map((i) => i.title), ['Health review']);
  });

  test('should search title, notes and tags', () {
    store.setQuery('QUARTER');
    expect(store.visible.single.title, 'Health review');
    store.setQuery('#maximo');
    expect(store.visible.single.title, 'Job plan checker');
  });

  test('should filter by stage', () async {
    final i = store.visible.first;
    await store.save(i.copyWith(stage: IdeaStage.building));
    store.setStageFilter(IdeaStage.building);
    expect(store.visible.single.id, i.id);
  });

  test('should put starred ideas first', () async {
    final last = store.visible.last;
    await store.toggleStar(last.id);
    expect(store.visible.first.id, last.id);
  });

  test('should persist saves and removals to repository', () async {
    final idea = Idea.create(title: 'New one');
    await store.save(idea);
    expect((await repo.loadAll()).length, 4);
    await store.remove(idea.id);
    expect((await repo.loadAll()).length, 3);
    expect(store.byId(idea.id), isNull);
  });

  test('should clear all data', () async {
    await store.clearAll();
    expect(store.total, 0);
    expect(await repo.loadAll(), isEmpty);
  });

  test('should export valid JSON with every idea', () {
    final decoded = jsonDecode(store.exportJson()) as Map<String, dynamic>;
    expect(decoded['app'], 'brainstash');
    expect((decoded['ideas'] as List).length, 3);
  });

  test('should surface an error when storage fails to open', () async {
    final s = IdeaStore(_FailingRepo());
    await s.load();
    expect(s.loaded, isTrue);
    expect(s.error, contains('Could not open your ideas'));
    expect(s.error, isNot(contains('keychain')), reason: 'no internals leaked');
  });

  group('attachments', () {
    late InMemoryIdeaRepository repo;
    late IdeaStore store;
    late Idea idea;
    final bytes = Uint8List.fromList([1, 2, 3]);

    setUp(() async {
      idea = Idea.create(title: 'Has files');
      repo = InMemoryIdeaRepository([idea]);
      store = IdeaStore(repo);
      await store.load();
    });

    test('should store bytes and link metadata', () async {
      final updated = await store.addAttachment(idea.id, name: 'a.pdf', kind: AttachmentKind.file, bytes: bytes);
      final a = updated.attachments.single;
      expect(a.name, 'a.pdf');
      expect(a.size, 3);
      expect(await store.readAttachment(a.id), bytes);
      expect(store.byId(idea.id)!.attachments, [a]);
    });

    test('should delete bytes when an attachment is removed', () async {
      final a = (await store.addAttachment(idea.id, name: 'a', kind: AttachmentKind.file, bytes: bytes))
          .attachments
          .single;
      await store.removeAttachment(idea.id, a.id);
      expect(store.byId(idea.id)!.attachments, isEmpty);
      expect(repo.files, isEmpty);
    });

    test('should delete bytes when the idea is deleted', () async {
      await store.addAttachment(idea.id, name: 'a', kind: AttachmentKind.file, bytes: bytes);
      await store.addAttachment(idea.id, name: 'b', kind: AttachmentKind.image, bytes: bytes);
      await store.remove(idea.id);
      expect(repo.files, isEmpty);
    });

    test('should enforce the per-idea limit', () async {
      for (var i = 0; i < Attachment.maxPerIdea; i++) {
        await store.addAttachment(idea.id, name: '$i', kind: AttachmentKind.file, bytes: bytes);
      }
      await expectLater(
        store.addAttachment(idea.id, name: 'x', kind: AttachmentKind.file, bytes: bytes),
        throwsA(isA<IdeaValidationError>()),
      );
      expect(repo.files.length, Attachment.maxPerIdea, reason: 'no orphaned bytes');
    });

    test('should find ideas by attachment name', () async {
      await store.addAttachment(idea.id, name: 'whiteboard-sketch.jpg', kind: AttachmentKind.image, bytes: bytes);
      store.setQuery('whiteboard');
      expect(store.visible.single.id, idea.id);
    });
  });
}
