import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'idea.dart';

enum AttachmentKind { image, file }

/// Metadata for a photo or document attached to an idea. The bytes live
/// encrypted in the repository's attachment store, keyed by [id].
@immutable
class Attachment {
  const Attachment._({
    required this.id,
    required this.name,
    required this.kind,
    required this.size,
    required this.createdAt,
  });

  static const maxBytes = 15 * 1024 * 1024;
  static const maxPerIdea = 20;
  static const maxName = 120;

  final String id;
  final String name;
  final AttachmentKind kind;
  final int size;
  final DateTime createdAt;

  factory Attachment.create({
    required String name,
    required AttachmentKind kind,
    required int size,
  }) {
    if (size <= 0) throw const IdeaValidationError('That file is empty.');
    if (size > maxBytes) {
      throw const IdeaValidationError('Attachments must be 15 MB or smaller.');
    }
    return Attachment._(
      id: const Uuid().v4(),
      name: safeName(name),
      kind: kind,
      size: size,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Display/file name with path parts and control characters removed, so a
  /// crafted name can't escape the temp directory when shared.
  static String safeName(String raw) {
    var n = raw.split(RegExp(r'[/\\]')).last;
    n = n.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    while (n.startsWith('.')) {
      n = n.substring(1);
    }
    if (n.isEmpty) n = 'attachment';
    if (n.length > maxName) {
      final dot = n.lastIndexOf('.');
      final ext = dot > 0 && n.length - dot <= 10 ? n.substring(dot) : '';
      n = n.substring(0, maxName - ext.length) + ext;
    }
    return n;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'size': size,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Attachment.fromMap(Map<dynamic, dynamic> m) => Attachment._(
        id: m['id'] as String,
        name: safeName(m['name'] as String),
        kind: m['kind'] == AttachmentKind.image.name ? AttachmentKind.image : AttachmentKind.file,
        size: (m['size'] as num).toInt(),
        createdAt: DateTime.parse(m['createdAt'] as String).toUtc(),
      );

  @override
  bool operator ==(Object other) =>
      other is Attachment &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.size == size &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, kind, size, createdAt);
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
