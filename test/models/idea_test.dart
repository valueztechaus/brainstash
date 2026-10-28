import 'package:brainstash/models/idea.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Idea.create', () {
    test('should trim title and apply defaults', () {
      final idea = Idea.create(title: '  Voice log  ');
      expect(idea.title, 'Voice log');
      expect(idea.kind, IdeaKind.other);
      expect(idea.stage, IdeaStage.spark);
      expect(idea.gut, GutFeel.good);
      expect(idea.starred, isFalse);
      expect(idea.id, hasLength(36));
    });

    test('should reject empty title', () {
      expect(() => Idea.create(title: '   '), throwsA(isA<IdeaValidationError>()));
    });

    test('should reject title over 200 chars', () {
      expect(() => Idea.create(title: 'x' * 201), throwsA(isA<IdeaValidationError>()));
    });

    test('should reject notes over 20000 chars', () {
      expect(
        () => Idea.create(title: 'a', notes: 'n' * 20001),
        throwsA(isA<IdeaValidationError>()),
      );
    });
  });

  group('Idea.normaliseTags', () {
    test('should lower-case, trim, strip hashes, de-dupe and drop empties', () {
      expect(
        Idea.normaliseTags([' Maximo', '#field', 'maximo', '', 'Voice ']),
        ['maximo', 'field', 'voice'],
      );
    });

    test('should parse comma separated input', () {
      expect(Idea.parseTags('a, b,,#C'), ['a', 'b', 'c']);
    });

    test('should cap at 20 tags of 32 chars', () {
      final tags = Idea.normaliseTags(List.generate(30, (i) => 't$i${'x' * 40}'));
      expect(tags, hasLength(20));
      expect(tags.every((t) => t.length <= 32), isTrue);
    });
  });

  group('serialisation', () {
    test('should round-trip through map', () {
      final idea = Idea.create(
        title: 'Job plan checker',
        notes: 'Validate safety steps',
        kind: IdeaKind.product,
        gut: GutFeel.mustBuild,
        tags: ['maximo'],
      ).copyWith(stage: IdeaStage.ready, starred: true, nextStep: 'Call two supervisors');
      final back = Idea.fromMap(idea.toMap());
      expect(back, idea);
    });

    test('should fall back to defaults on unknown enum values', () {
      final map = Idea.create(title: 'x').toMap()
        ..['kind'] = 'spaceship'
        ..['stage'] = 'nope';
      final back = Idea.fromMap(map);
      expect(back.kind, IdeaKind.other);
      expect(back.stage, IdeaStage.spark);
    });

    test('should throw on malformed map', () {
      expect(() => Idea.fromMap({'id': 1}), throwsA(isA<IdeaValidationError>()));
    });
  });

  test('copyWith should bump updatedAt and validate', () {
    final idea = Idea.create(title: 'a');
    final edited = idea.copyWith(title: 'b');
    expect(edited.updatedAt.isBefore(idea.updatedAt), isFalse);
    expect(() => idea.copyWith(title: ''), throwsA(isA<IdeaValidationError>()));
  });

  test('shareText should include title, kind, stage and notes', () {
    final idea = Idea.create(title: 'T', notes: 'N', kind: IdeaKind.service, tags: ['x']);
    final text = idea.shareText();
    expect(text, contains('T'));
    expect(text, contains('Service'));
    expect(text, contains('Spark'));
    expect(text, contains('N'));
    expect(text, contains('#x'));
  });
}
