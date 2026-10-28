import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/idea_repository.dart';
import '../models/attachment.dart';
import '../models/idea.dart';
import 'search.dart';

/// App state: the idea list plus the inbox's search and filters.
class IdeaStore extends ChangeNotifier {
  IdeaStore(this._repo);

  final IdeaRepository _repo;
  List<Idea> _all = const [];
  String _query = '';
  IdeaKind? _kind;
  IdeaStage? _stage;
  bool _loaded = false;
  String? _error;

  bool get loaded => _loaded;
  String? get error => _error;
  String get query => _query;
  IdeaKind? get kindFilter => _kind;
  IdeaStage? get stageFilter => _stage;
  int get total => _all.length;

  Future<void> load() async {
    try {
      _all = await _repo.loadAll();
      _error = null;
    } on Object catch (e) {
      debugPrint('Load failed: $e');
      _error = 'Could not open your ideas. Restart the app and try again.';
    }
    _loaded = true;
    notifyListeners();
  }

  /// Starred first, then most recently updated.
  List<Idea> get visible {
    final terms = searchTerms(_query);
    final list = _all.where((i) {
      if (_kind != null && i.kind != _kind) return false;
      if (_stage != null && i.stage != _stage) return false;
      return matchesSearch(i, terms);
    }).toList()
      ..sort((a, b) {
        if (a.starred != b.starred) return a.starred ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  int countFor(IdeaKind? kind) =>
      kind == null ? _all.length : _all.where((i) => i.kind == kind).length;

  Idea? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setKindFilter(IdeaKind? k) {
    _kind = k;
    notifyListeners();
  }

  void setStageFilter(IdeaStage? s) {
    _stage = s;
    notifyListeners();
  }

  Future<void> save(Idea idea) async {
    await _repo.put(idea);
    _all = [..._all.where((i) => i.id != idea.id), idea];
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final files = byId(id)?.attachments ?? const <Attachment>[];
    await _repo.delete(id);
    _all = _all.where((i) => i.id != id).toList();
    notifyListeners();
    for (final a in files) {
      await _repo.deleteFile(a.id);
    }
  }

  /// Stores [bytes] encrypted and links them to the idea. Returns the
  /// updated idea. Throws [IdeaValidationError] for size/count limits.
  Future<Idea> addAttachment(
    String ideaId, {
    required String name,
    required AttachmentKind kind,
    required Uint8List bytes,
  }) async {
    final idea = byId(ideaId);
    if (idea == null) throw const IdeaValidationError('That idea no longer exists.');
    if (idea.attachments.length >= Attachment.maxPerIdea) {
      throw const IdeaValidationError('An idea can have up to ${Attachment.maxPerIdea} attachments');
    }
    final a = Attachment.create(name: name, kind: kind, size: bytes.length);
    await _repo.putFile(a.id, bytes);
    final updated = idea.copyWith(attachments: [...idea.attachments, a]);
    try {
      await save(updated);
    } on Object {
      await _repo.deleteFile(a.id);
      rethrow;
    }
    return updated;
  }

  Future<Idea?> removeAttachment(String ideaId, String attachmentId) async {
    final idea = byId(ideaId);
    if (idea == null) return null;
    final updated =
        idea.copyWith(attachments: idea.attachments.where((a) => a.id != attachmentId).toList());
    await save(updated);
    await _repo.deleteFile(attachmentId);
    return updated;
  }

  Future<Uint8List?> readAttachment(String attachmentId) => _repo.readFile(attachmentId);

  Future<void> toggleStar(String id) async {
    final i = byId(id);
    if (i != null) await save(i.copyWith(starred: !i.starred));
  }

  Future<void> clearAll() async {
    await _repo.clear();
    _all = const [];
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'brainstash',
        'schema': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'ideas': _all.map((i) => i.toMap()).toList(),
      });
}
