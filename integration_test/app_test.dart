import 'package:brainstash/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end on a real simulator: real Keychain, real encrypted Hive store.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> capture(WidgetTester t, String title, String kind, String notes) async {
    await t.tap(find.byKey(const Key('capture-fab')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('capture-title')), title);
    await t.enterText(find.byKey(const Key('capture-notes')), notes);
    await t.tap(find.text(kind).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('capture-save')));
    await t.pumpAndSettle();
  }

  testWidgets('capture, review and triage ideas end to end', (t) async {
    await app.main();
    await t.pumpAndSettle(const Duration(seconds: 2));

    await capture(t, 'Field techs lose paper notes', 'Problem',
        'Notes written on site never make it back into the work order.');
    await capture(t, 'Asset health review service', 'Service',
        'Quarterly review package for utilities clients.');
    await capture(t, 'Offline job-plan checker', 'Product',
        'Validate job plans for missing safety steps before upload.');

    // Star one so the ordering shows.
    await t.tap(find.text('Offline job-plan checker'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Star'));
    await t.tap(find.bySemanticsLabel('Stage Exploring'));
    await t.pumpAndSettle();
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    // Capture sheet mid-entry.
    await t.tap(find.byKey(const Key('capture-fab')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('capture-title')), 'Voice-first inspection log');
    await t.enterText(find.byKey(const Key('capture-notes')),
        "Crews wear gloves and can't type. Speak notes, attach them to the work order.");
    await t.tap(find.text('Product').last);
    await t.tap(find.text('Must build'));
    await t.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await binding.takeScreenshot('capture');
    await t.tap(find.byKey(const Key('capture-save')));
    await t.pumpAndSettle();

    expect(find.text('All · 4'), findsOneWidget);
    await binding.takeScreenshot('inbox');

    // Detail view.
    await t.tap(find.text('Voice-first inspection log'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Stage Ready'));
    await t.pumpAndSettle();
    await binding.takeScreenshot('detail');
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    // Filter + search.
    await t.tap(find.text('Problem · 1'));
    await t.pumpAndSettle();
    expect(find.text('Field techs lose paper notes'), findsOneWidget);
    expect(find.text('Asset health review service'), findsNothing);
    await t.tap(find.text('All · 4'));
    await t.enterText(find.byKey(const Key('search')), 'quarterly');
    await t.pumpAndSettle();
    expect(find.text('Asset health review service'), findsOneWidget);
    await t.enterText(find.byKey(const Key('search')), '');
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    await binding.takeScreenshot('settings');
  });
}
