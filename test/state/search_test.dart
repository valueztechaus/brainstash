import 'package:brainstash/models/idea.dart';
import 'package:brainstash/state/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final idea = Idea.create(
    title: 'Dog walker marketplace',
    notes: 'Owners book walks by the hour.',
    kind: IdeaKind.product,
    tags: const ['pets'],
  );

  bool hit(String q) => matchesSearch(idea, searchTerms(q));

  test('should match every word in any order across fields', () {
    expect(hit('marketplace dog'), isTrue);
    expect(hit('hour pets'), isTrue);
    expect(hit('dog invoices'), isFalse);
  });

  test('should match word forms loosely', () {
    expect(hit('dog walking'), isTrue);
    expect(hit('dogs'), isTrue);
    expect(hit('booking'), isTrue);
  });

  test('should ignore filler words', () {
    expect(hit('an app for the dogs'), isFalse, reason: '"app" is a real word not in the idea');
    expect(hit('marketplace for dogs'), isTrue);
  });

  test('should match kind and stage labels', () {
    expect(hit('product'), isTrue);
    expect(hit('spark'), isTrue);
    expect(hit('problem'), isFalse);
  });

  test('should accept hashtags', () {
    expect(hit('#pets'), isTrue);
  });

  test('should match everything for an empty query', () {
    expect(searchTerms('   '), isEmpty);
    expect(hit(''), isTrue);
  });
}
