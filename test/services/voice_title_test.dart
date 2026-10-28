import 'package:brainstash/services/voice_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('titleFromTranscript', () {
    test('should use the first sentence', () {
      expect(
        titleFromTranscript('Voice log for field crews. They wear gloves and cannot type.'),
        'Voice log for field crews',
      );
    });

    test('should capitalise the first letter', () {
      expect(titleFromTranscript('an app for dog walkers'), 'An app for dog walkers');
    });

    test('should cut long run-on speech at a word boundary', () {
      final t = titleFromTranscript(
          'so I was thinking we could build a marketplace where small trades businesses '
          'swap spare stock with each other without paying listing fees');
      expect(t.length, lessThanOrEqualTo(61));
      expect(t.endsWith('…'), isTrue);
      expect(t.contains('  '), isFalse);
    });

    test('should return empty for blank speech', () {
      expect(titleFromTranscript('   '), '');
    });

    test('should handle question and exclamation marks', () {
      expect(titleFromTranscript('Why do invoices take so long? Maybe automate.'),
          'Why do invoices take so long?');
    });
  });

  group('mergeTranscript', () {
    test('should append to existing notes with a blank line', () {
      expect(mergeTranscript('Existing', 'new words'), 'Existing\n\nnew words');
    });

    test('should return transcript alone when notes empty', () {
      expect(mergeTranscript('  ', 'new words'), 'new words');
    });
  });
}
