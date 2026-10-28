import 'dart:convert';

import 'package:brainstash/data/idea_repository.dart';
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
}
