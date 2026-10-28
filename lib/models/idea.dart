import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'attachment.dart';

enum IdeaKind {
  product('Product'),
  service('Service'),
  problem('Problem'),
  other('Other');

  const IdeaKind(this.label);
  final String label;
}

enum IdeaStage {
  spark('Spark'),
  exploring('Exploring'),
  ready('Ready'),
  building('Building'),
  shelved('Shelved');

  const IdeaStage(this.label);
  final String label;
}

enum GutFeel {
  meh('Meh'),
  good('Good'),
  mustBuild('Must build');

  const GutFeel(this.label);
  final String label;
}

class IdeaValidationError implements Exception {
  const IdeaValidationError(this.message);
  final String message;

  @override
  String toString() => 'IdeaValidationError: $message';
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

@immutable
class Idea {
  const Idea._({
    required this.id,
    required this.title,
    required this.notes,
    required this.kind,
    required this.stage,
    required this.gut,
    required this.nextStep,
    required this.tags,
    required this.starred,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  static const maxTitle = 200;
  static const maxNotes = 20000;
  static const maxNextStep = 500;
  static const maxTags = 20;
  static const maxTagLength = 32;

  final String id;
  final String title;
  final String notes;
  final IdeaKind kind;
  final IdeaStage stage;
  final GutFeel gut;
  final String nextStep;
  final List<String> tags;
  final bool starred;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Attachment> attachments;

  factory Idea.create({
    required String title,
    String notes = '',
    IdeaKind kind = IdeaKind.other,
    GutFeel gut = GutFeel.good,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().toUtc();
    return Idea._validated(
      id: const Uuid().v4(),
      title: title,
      notes: notes,
      kind: kind,
      stage: IdeaStage.spark,
      gut: gut,
      nextStep: '',
      tags: tags,
      starred: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Idea._validated({
    required String id,
    required String title,
    required String notes,
    required IdeaKind kind,
    required IdeaStage stage,
    required GutFeel gut,
    required String nextStep,
    required List<String> tags,
    required bool starred,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<Attachment> attachments = const [],
  }) {
    final t = title.trim();
    if (t.isEmpty) throw const IdeaValidationError('Title is required');
    if (t.length > maxTitle) {
      throw const IdeaValidationError('Title must be $maxTitle characters or fewer');
    }
    if (notes.length > maxNotes) {
      throw const IdeaValidationError('Notes must be $maxNotes characters or fewer');
    }
    final step = nextStep.trim();
    if (step.length > maxNextStep) {
      throw const IdeaValidationError('Next step must be $maxNextStep characters or fewer');
    }
    if (attachments.length > Attachment.maxPerIdea) {
      throw const IdeaValidationError('An idea can have up to ${Attachment.maxPerIdea} attachments');
    }
    return Idea._(
      id: id,
      title: t,
      notes: notes,
      kind: kind,
      stage: stage,
      gut: gut,
      nextStep: step,
      tags: List.unmodifiable(normaliseTags(tags)),
      starred: starred,
      createdAt: createdAt,
      updatedAt: updatedAt,
      attachments: List.unmodifiable(attachments),
    );
  }

  static List<String> normaliseTags(Iterable<String> raw) {
    final out = <String>[];
    for (final r in raw) {
      var t = r.trim().toLowerCase().replaceAll(RegExp(r'^#+'), '');
      t = t.replaceAll(RegExp(r'\s+'), '-');
      if (t.isEmpty) continue;
      if (t.length > maxTagLength) t = t.substring(0, maxTagLength);
      if (!out.contains(t)) out.add(t);
      if (out.length == maxTags) break;
    }
    return out;
  }

  static List<String> parseTags(String input) => normaliseTags(input.split(','));

  Idea copyWith({
    String? title,
    String? notes,
    IdeaKind? kind,
    IdeaStage? stage,
    GutFeel? gut,
    String? nextStep,
    List<String>? tags,
    bool? starred,
    List<Attachment>? attachments,
  }) {
    return Idea._validated(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      kind: kind ?? this.kind,
      stage: stage ?? this.stage,
      gut: gut ?? this.gut,
      nextStep: nextStep ?? this.nextStep,
      tags: tags ?? this.tags,
      starred: starred ?? this.starred,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'kind': kind.name,
        'stage': stage.name,
        'gut': gut.name,
        'nextStep': nextStep,
        'tags': tags,
        'starred': starred,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'attachments': attachments.map((a) => a.toMap()).toList(),
      };

  factory Idea.fromMap(Map<dynamic, dynamic> m) {
    try {
      return Idea._validated(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: (m['notes'] as String?) ?? '',
        kind: _enumByName(IdeaKind.values, m['kind'], IdeaKind.other),
        stage: _enumByName(IdeaStage.values, m['stage'], IdeaStage.spark),
        gut: _enumByName(GutFeel.values, m['gut'], GutFeel.good),
        nextStep: (m['nextStep'] as String?) ?? '',
        tags: ((m['tags'] as List?) ?? const []).whereType<String>().toList(),
        starred: (m['starred'] as bool?) ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String).toUtc(),
        updatedAt: DateTime.parse(m['updatedAt'] as String).toUtc(),
        attachments: ((m['attachments'] as List?) ?? const [])
            .whereType<Map<dynamic, dynamic>>()
            .map(Attachment.fromMap)
            .toList(),
      );
    } on IdeaValidationError {
      rethrow;
    } on Object catch (e) {
      throw IdeaValidationError('Malformed idea record: $e');
    }
  }

  String shareText() {
    final b = StringBuffer()
      ..writeln(title)
      ..writeln('${kind.label} · ${stage.label} · ${gut.label}');
    if (notes.isNotEmpty) b..writeln()..writeln(notes);
    if (nextStep.isNotEmpty) b..writeln()..writeln('Next step: $nextStep');
    if (tags.isNotEmpty) b..writeln()..writeln(tags.map((t) => '#$t').join(' '));
    return b.toString().trimRight();
  }

  @override
  bool operator ==(Object other) =>
      other is Idea &&
      other.id == id &&
      other.title == title &&
      other.notes == notes &&
      other.kind == kind &&
      other.stage == stage &&
      other.gut == gut &&
      other.nextStep == nextStep &&
      listEquals(other.tags, tags) &&
      other.starred == starred &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      listEquals(other.attachments, attachments);

  @override
  int get hashCode => Object.hash(id, title, notes, kind, stage, gut, nextStep,
      Object.hashAll(tags), starred, createdAt, updatedAt, Object.hashAll(attachments));
}
