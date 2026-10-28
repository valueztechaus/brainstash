import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/idea_repository.dart';
import '../models/idea.dart';

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
    final q = _query.trim().toLowerCase();
    final list = _all.where((i) {
      if (_kind != null && i.kind != _kind) return false;
      if (_stage != null && i.stage != _stage) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.notes.toLowerCase().contains(q) ||
          i.nextStep.toLowerCase().contains(q) ||
          i.tags.any((t) => t.contains(q.replaceFirst('#', '')));
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
    await _repo.delete(id);
    _all = _all.where((i) => i.id != id).toList();
    notifyListeners();
  }

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
