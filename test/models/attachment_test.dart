import 'package:brainstash/models/attachment.dart';
import 'package:brainstash/models/idea.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attachment', () {
    test('should strip path parts and control characters from names', () {
      expect(Attachment.safeName('../../etc/passwd'), 'passwd');
      expect(Attachment.safeName(r'C:\docs\plan.pdf'), 'plan.pdf');
      expect(Attachment.safeName('.hidden'), 'hidden');
      expect(Attachment.safeName('a\u0000b\nc.txt'), 'abc.txt');
      expect(Attachment.safeName('   '), 'attachment');
    });

    test('should cap long names but keep the extension', () {
      final n = Attachment.safeName('${'x' * 300}.pdf');
      expect(n.length, Attachment.maxName);
      expect(n.endsWith('.pdf'), isTrue);
    });

    test('should reject empty and oversized files', () {
      expect(() => Attachment.create(name: 'a', kind: AttachmentKind.file, size: 0),
          throwsA(isA<IdeaValidationError>()));
      expect(() => Attachment.create(name: 'a', kind: AttachmentKind.file, size: Attachment.maxBytes + 1),
          throwsA(isA<IdeaValidationError>()));
    });

    test('should round-trip through the idea map', () {
      final a = Attachment.create(name: 'sketch.jpg', kind: AttachmentKind.image, size: 1234);
      final idea = Idea.create(title: 'With photo').copyWith(attachments: [a]);
      final back = Idea.fromMap(idea.toMap());
      expect(back, idea);
      expect(back.attachments.single.kind, AttachmentKind.image);
    });

    test('should read old records without attachments', () {
      final m = Idea.create(title: 'Old').toMap()..remove('attachments');
      expect(Idea.fromMap(m).attachments, isEmpty);
    });

    test('should format sizes', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(3 * 1024 * 1024), '3.0 MB');
    });
  });
}
