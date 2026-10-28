import '../models/idea.dart';

/// Words too common to narrow a search; dropped unless they're all there is.
const _filler = {
  'a', 'an', 'the', 'for', 'of', 'to', 'and', 'or', 'about', 'with', 'my', 'on', 'in', 'is', //
  'that', 'this', 'it',
};

/// Splits a query into lower-case, loosely stemmed terms. Every term must
/// appear somewhere in an idea for it to match, in any order.
List<String> searchTerms(String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .toList();
  final meaningful = words.where((w) => !_filler.contains(w)).toList();
  return (meaningful.isEmpty ? words : meaningful).map(_stem).toList();
}

/// Crude suffix strip so "walking" finds "walker" and "dogs" finds "dog".
String _stem(String word) {
  for (final suffix in const ['ing', 'ers', 'ies', 'er', 'ed', 'es', 's']) {
    if (word.length - suffix.length >= 3 && word.endsWith(suffix)) {
      return word.substring(0, word.length - suffix.length);
    }
  }
  return word;
}

bool matchesSearch(Idea idea, List<String> terms) {
  if (terms.isEmpty) return true;
  final haystack = [
    idea.title,
    idea.notes,
    idea.nextStep,
    idea.tags.join(' '),
    idea.kind.label,
    idea.stage.label,
    ...idea.attachments.map((a) => a.name),
  ].join(' ').toLowerCase();
  return terms.every(haystack.contains);
}
