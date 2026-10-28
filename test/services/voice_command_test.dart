import 'package:brainstash/services/voice_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractSaveCommand', () {
    test('should detect "save the idea" at the end and strip it', () {
      final r = extractSaveCommand('An app for dog walkers. Save the idea');
      expect(r.save, isTrue);
      expect(r.text, 'An app for dog walkers.');
    });

    test('should accept common variants with punctuation and filler', () {
      for (final phrase in [
        'Booking tool, okay save idea.',
        'Booking tool. Please save this idea!',
        "Booking tool. That's it, save it",
        'Booking tool. Done save',
        'Booking tool save my idea now',
        'Booking tool. Save it now.',
      ]) {
        final r = extractSaveCommand(phrase);
        expect(r.save, isTrue, reason: phrase);
        expect(r.text, startsWith('Booking tool'), reason: phrase);
        expect(r.text.toLowerCase(), isNot(contains('save')), reason: phrase);
      }
    });

    test('should not fire on ordinary speech that mentions saving', () {
      for (final phrase in [
        'An app that helps people save money',
        'Snap a recipe and save it',
        'Save the idea board for later sprints is a feature',
        'A place to store it',
      ]) {
        expect(extractSaveCommand(phrase).save, isFalse, reason: phrase);
      }
    });

    test('should return the transcript unchanged when no command', () {
      final r = extractSaveCommand('Just thinking out loud');
      expect(r.save, isFalse);
      expect(r.text, 'Just thinking out loud');
    });

    test('should leave empty text when only the command was spoken', () {
      final r = extractSaveCommand('Save the idea');
      expect(r.save, isTrue);
      expect(r.text, '');
    });
  });

  group('searchQueryFromSpeech', () {
    test('should strip lead-in phrases', () {
      expect(searchQueryFromSpeech('Search for dog walking'), 'dog walking');
      expect(searchQueryFromSpeech('Find my ideas about invoices.'), 'invoices');
      expect(searchQueryFromSpeech('show me problems'), 'problems');
    });

    test('should keep plain queries', () {
      expect(searchQueryFromSpeech('Maximo'), 'maximo');
    });

    test('should keep the words when speech is only lead-in words', () {
      expect(searchQueryFromSpeech('ideas'), 'ideas');
    });
  });
}
