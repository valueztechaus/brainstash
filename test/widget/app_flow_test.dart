import 'dart:typed_data';

import 'package:brainstash/app.dart';
import 'package:brainstash/data/idea_repository.dart';
import 'package:brainstash/data/key_store.dart';
import 'package:brainstash/models/attachment.dart';
import 'package:brainstash/models/idea.dart';
import 'package:brainstash/services/app_lock.dart';
import 'package:brainstash/services/attachment_picker.dart';
import 'package:brainstash/services/voice_input.dart';
import 'package:brainstash/state/idea_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVoice implements VoiceInput {
  FakeVoice({this.status = VoiceStatus.idle, this.words = const [], this.endWith = VoiceStatus.idle});

  final VoiceStatus status;
  final List<String> words;
  final VoiceStatus endWith;
  bool cancelled = false;
  int stops = 0;
  Duration? lastPauseFor;

  @override
  Future<VoiceStatus> prepare() async => status;

  @override
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<VoiceStatus> onDone,
    Duration pauseFor = const Duration(seconds: 4),
    Duration listenFor = const Duration(minutes: 2),
  }) async {
    lastPauseFor = pauseFor;
    for (final w in words) {
      onText(w);
    }
    onDone(endWith);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async => cancelled = true;
}

class FakePicker implements AttachmentPicker {
  FakePicker({this.result, this.error});

  final PickedAttachment? result;
  final AttachmentPickError? error;
  final sources = <AttachmentSource>[];

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return result;
  }
}

final _photo = (
  name: 'Photo.jpg',
  kind: AttachmentKind.image,
  bytes: Uint8List.fromList(List.filled(64, 7)),
);
final _pdf = (name: 'pitch.pdf', kind: AttachmentKind.file, bytes: Uint8List.fromList([37, 80, 68, 70]));

Future<(IdeaStore, AppLock)> _pump(
  WidgetTester tester, {
  List<Idea> seed = const [],
  bool lockEnabled = false,
  bool authResult = true,
  VoiceInput? voice,
  AttachmentPicker? picker,
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
  await tester.pumpWidget(BrainstashApp(
    store: store,
    lock: lock,
    voice: voice ?? FakeVoice(),
    picker: picker ?? FakePicker(),
  ));
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

  testWidgets('should fill title and notes from voice and save', (tester) async {
    final voice = FakeVoice(words: [
      'Voice log',
      'Voice log for field crews. They wear gloves.',
    ]);
    final (store, _) = await _pump(tester, voice: voice);
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Voice log for field crews'), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture-save')));
    await tester.pumpAndSettle();
    final saved = store.visible.single;
    expect(saved.title, 'Voice log for field crews');
    expect(saved.notes, 'Voice log for field crews. They wear gloves.');
  });

  testWidgets('should not overwrite a typed title or notes when dictating', (tester) async {
    final (store, _) = await _pump(tester, voice: FakeVoice(words: ['extra thoughts']));
    await tester.tap(find.byKey(const Key('capture-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('capture-title')), 'My title');
    await tester.enterText(find.byKey(const Key('capture-notes')), 'Typed first');
    await tester.tap(find.byKey(const Key('voice-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-save')));
    await tester.pumpAndSettle();
    final saved = store.visible.single;
    expect(saved.title, 'My title');
    expect(saved.notes, 'Typed first\n\nextra thoughts');
  });

  testWidgets('should explain when on-device speech is unavailable', (tester) async {
    await _pump(tester, voice: FakeVoice(status: VoiceStatus.unavailable));
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();
    expect(find.textContaining('never sent off your phone'), findsOneWidget);
    expect(tester.widget<TextButton>(find.byKey(const Key('capture-save'))).onPressed, isNull);
  });

  testWidgets('should point to Settings when permission denied', (tester) async {
    await _pump(tester, voice: FakeVoice(status: VoiceStatus.denied));
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();
    expect(find.textContaining('iOS Settings'), findsOneWidget);
  });

  testWidgets('should save automatically when "save the idea" is spoken', (tester) async {
    final voice = FakeVoice(words: [
      'Invoice chaser',
      'Invoice chaser for tradies. Save the',
      'Invoice chaser for tradies. Save the idea',
      'Invoice chaser for tradies. Save the idea.',
    ]);
    final (store, _) = await _pump(tester, voice: voice);
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('capture-save')), findsNothing, reason: 'sheet closed');
    final saved = store.visible.single;
    expect(saved.title, 'Invoice chaser for tradies');
    expect(saved.notes, 'Invoice chaser for tradies.');
    expect(voice.stops, 1);
    expect(voice.lastPauseFor, const Duration(seconds: 30), reason: 'waits through thinking pauses');
  });

  testWidgets('should not save when only the command is spoken', (tester) async {
    final (store, _) = await _pump(tester, voice: FakeVoice(words: ['Save the idea']));
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();
    expect(store.total, 0);
    expect(find.textContaining('Say your idea first'), findsOneWidget);
  });

  testWidgets('should keep the sheet open after a silent pause', (tester) async {
    final (store, _) = await _pump(tester, voice: FakeVoice(words: ['Thinking about a mesh wifi planner']));
    await tester.tap(find.byKey(const Key('voice-fab')));
    await tester.pumpAndSettle();
    expect(store.total, 0);
    expect(find.textContaining('Paused'), findsOneWidget);
    expect(find.text('Thinking about a mesh wifi planner'), findsWidgets);
  });

  testWidgets('should search by voice', (tester) async {
    final (store, _) = await _pump(
      tester,
      seed: [
        Idea.create(title: 'Dog walker marketplace'),
        Idea.create(title: 'Invoice chaser'),
      ],
      voice: FakeVoice(words: ['Find my ideas about dog walking.']),
    );
    await tester.tap(find.byKey(const Key('search-voice')));
    await tester.pumpAndSettle();
    expect(store.query, 'dog walking');
    expect(find.text('Dog walker marketplace'), findsOneWidget);
    expect(find.text('Invoice chaser'), findsNothing);

    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Invoice chaser'), findsOneWidget);
  });

  testWidgets('should match typed search words in any order', (tester) async {
    await _pump(tester, seed: [
      Idea.create(title: 'Dog walker marketplace', notes: 'Owners book by the hour'),
      Idea.create(title: 'Invoice chaser'),
    ]);
    await tester.enterText(find.byKey(const Key('search')), 'hour dogs');
    await tester.pumpAndSettle();
    expect(find.text('Dog walker marketplace'), findsOneWidget);
    expect(find.text('Invoice chaser'), findsNothing);
  });

  Future<void> openDetail(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> attachFrom(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(const Key('attach-add')));
    await tester.tap(find.byKey(const Key('attach-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('should attach a photo to an idea and remove it', (tester) async {
    final picker = FakePicker(result: _photo);
    final (store, _) = await _pump(tester, seed: [Idea.create(title: 'Whiteboard idea')], picker: picker);
    await openDetail(tester, 'Whiteboard idea');
    await attachFrom(tester, 'attach-camera');

    expect(picker.sources, [AttachmentSource.camera]);
    final idea = store.visible.single;
    final a = idea.attachments.single;
    expect(a.kind, AttachmentKind.image);
    expect(await store.readAttachment(a.id), _photo.bytes);
    expect(find.byKey(ValueKey('attachment-${a.id}')), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('attachment-${a.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attachment-remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attachment-remove-confirm')));
    await tester.pumpAndSettle();
    expect(store.visible.single.attachments, isEmpty);
    expect(await store.readAttachment(a.id), isNull);
  });

  testWidgets('should keep unsaved text edits when attaching', (tester) async {
    final (store, _) = await _pump(tester, seed: [Idea.create(title: 'Draft')], picker: FakePicker(result: _pdf));
    await openDetail(tester, 'Draft');
    await tester.enterText(find.byKey(const Key('detail-title')), 'Draft renamed');
    await attachFrom(tester, 'attach-files');
    await tester.pageBack();
    await tester.pumpAndSettle();
    final idea = store.visible.single;
    expect(idea.title, 'Draft renamed');
    expect(idea.attachments.single.name, 'pitch.pdf');
  });

  testWidgets('should attach files while capturing a new idea', (tester) async {
    final (store, _) = await _pump(tester, picker: FakePicker(result: _pdf));
    await tester.tap(find.byKey(const Key('capture-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('capture-title')), 'Pitch deck idea');
    await attachFrom(tester, 'attach-files');
    expect(store.total, 0, reason: 'nothing stored until Save');
    await tester.tap(find.byKey(const Key('capture-save')));
    await tester.pumpAndSettle();
    final idea = store.visible.single;
    expect(idea.attachments.single.name, 'pitch.pdf');
    expect(await store.readAttachment(idea.attachments.single.id), _pdf.bytes);
    expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget, reason: 'card shows paperclip');
  });

  testWidgets('should explain picker errors', (tester) async {
    await _pump(
      tester,
      seed: [Idea.create(title: 'No camera')],
      picker: FakePicker(error: const AttachmentPickError('Allow Camera access for Brainstash in iOS Settings.')),
    );
    await openDetail(tester, 'No camera');
    await attachFrom(tester, 'attach-camera');
    expect(find.textContaining('Allow Camera access'), findsOneWidget);
  });

  testWidgets('should do nothing when the picker is cancelled', (tester) async {
    final (store, _) = await _pump(tester, seed: [Idea.create(title: 'Cancel me')]);
    await openDetail(tester, 'Cancel me');
    await attachFrom(tester, 'attach-gallery');
    expect(store.visible.single.attachments, isEmpty);
  });

  testWidgets('should credit Valueztech in Settings', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('valueztech-logo')), 200);
    expect(find.byKey(const Key('valueztech-logo')), findsOneWidget);
    expect(find.text('www.valueztech.com'), findsOneWidget);
  });
}
