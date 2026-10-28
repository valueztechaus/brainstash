import 'package:brainstash/app.dart';
import 'package:brainstash/data/idea_repository.dart';
import 'package:brainstash/data/key_store.dart';
import 'package:brainstash/models/idea.dart';
import 'package:brainstash/services/app_lock.dart';
import 'package:brainstash/state/idea_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(IdeaStore, AppLock)> _pump(
  WidgetTester tester, {
  List<Idea> seed = const [],
  bool lockEnabled = false,
  bool authResult = true,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final keys = InMemoryKeyStore();
  await keys.writeFlag(AppLock.flag, value: lockEnabled);
  final store = IdeaStore(InMemoryIdeaRepository(seed));
  final lock = AppLock(
    keyStore: keys,
    authenticator: (_) async => authResult,
    supported: () async => true,
  );
  await store.load();
  await lock.init();
  await tester.pumpWidget(BrainstashApp(store: store, lock: lock));
  await tester.pumpAndSettle();
  return (store, lock);
}

void main() {
  testWidgets('should show empty state on first launch', (tester) async {
    await _pump(tester);
    expect(find.text('Your stash is empty'), findsOneWidget);
  });

  testWidgets('should capture an idea with only a title', (tester) async {
    final (store, _) = await _pump(tester);
    await tester.tap(find.byKey(const Key('capture-fab')));
    await tester.pumpAndSettle();

    final save = find.byKey(const Key('capture-save'));
    expect(tester.widget<TextButton>(save).onPressed, isNull, reason: 'disabled until title');

    await tester.enterText(find.byKey(const Key('capture-title')), 'Voice inspection log');
    await tester.pump();
    await tester.tap(find.text('Product'));
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(store.total, 1);
    expect(store.visible.single.kind, IdeaKind.product);
    expect(find.text('Voice inspection log'), findsOneWidget);
  });

  testWidgets('should filter inbox by kind chip', (tester) async {
    await _pump(tester, seed: [
      Idea.create(title: 'A product', kind: IdeaKind.product),
      Idea.create(title: 'A problem', kind: IdeaKind.problem),
    ]);
    await tester.tap(find.text('Problem · 1'));
    await tester.pumpAndSettle();
    expect(find.text('A problem'), findsOneWidget);
    expect(find.text('A product'), findsNothing);
  });

  testWidgets('should edit stage and title in detail and save on back', (tester) async {
    final idea = Idea.create(title: 'Old title');
    final (store, _) = await _pump(tester, seed: [idea]);
    await tester.tap(find.text('Old title'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Stage Building'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('detail-title')), 'New title');
    await tester.pageBack();
    await tester.pumpAndSettle();

    final saved = store.byId(idea.id)!;
    expect(saved.stage, IdeaStage.building);
    expect(saved.title, 'New title');
    expect(find.text('New title'), findsOneWidget);
  });

  testWidgets('should keep both edits when star and stage are tapped quickly', (tester) async {
    final idea = Idea.create(title: 'Quick taps');
    final (store, _) = await _pump(tester, seed: [idea]);
    await tester.tap(find.text('Quick taps'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Star'));
    await tester.tap(find.bySemanticsLabel('Stage Exploring'));
    await tester.pumpAndSettle();
    final saved = store.byId(idea.id)!;
    expect(saved.starred, isTrue);
    expect(saved.stage, IdeaStage.exploring);
  });

  testWidgets('should refuse to leave detail with an empty title', (tester) async {
    final idea = Idea.create(title: 'Keep me');
    final (store, _) = await _pump(tester, seed: [idea]);
    await tester.tap(find.text('Keep me'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('detail-title')), '  ');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(store.byId(idea.id)!.title, 'Keep me');
  });

  testWidgets('should delete an idea after confirmation', (tester) async {
    final (store, _) = await _pump(tester, seed: [Idea.create(title: 'Doomed')]);
    await tester.tap(find.text('Doomed'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.total, 0);
  });

  testWidgets('should hide content while locked and reveal after auth', (tester) async {
    await _pump(tester, seed: [Idea.create(title: 'Secret')], lockEnabled: true, authResult: false);
    expect(find.text('Secret').hitTestable(), findsNothing);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('should unlock when auth succeeds', (tester) async {
    await _pump(tester, seed: [Idea.create(title: 'Secret')], lockEnabled: true);
    expect(find.text('Secret').hitTestable(), findsOneWidget);
  });
}
