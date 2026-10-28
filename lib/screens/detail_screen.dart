import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../models/idea.dart';
import '../theme.dart';
import '../widgets/choice_row.dart';
import '../widgets/stage_picker.dart';

/// View and edit one idea. Edits save when leaving the screen.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.ideaId});

  final String ideaId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Idea _idea;
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _next;
  late final TextEditingController _tags;
  bool _deleted = false;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _idea = AppScope.of(context).store.byId(widget.ideaId)!;
    _title = TextEditingController(text: _idea.title);
    _notes = TextEditingController(text: _idea.notes);
    _next = TextEditingController(text: _idea.nextStep);
    _tags = TextEditingController(text: _idea.tags.join(', '));
    _ready = true;
  }

  @override
  void dispose() {
    for (final c in [_title, _notes, _next, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Returns null on success or a validation message.
  Future<String?> _persist() async {
    if (_deleted) return null;
    try {
      final edited = _idea.copyWith(
        title: _title.text,
        notes: _notes.text,
        nextStep: _next.text,
        tags: Idea.parseTags(_tags.text),
      );
      if (!_sameContent(edited)) {
        await AppScope.of(context).store.save(edited);
        _idea = edited;
      }
      return null;
    } on IdeaValidationError catch (e) {
      return e.message;
    }
  }

  bool _sameContent(Idea e) =>
      e.title == _idea.title &&
      e.notes == _idea.notes &&
      e.nextStep == _idea.nextStep &&
      e.tags.join() == _idea.tags.join();

  /// Applies a one-tap edit. `_idea` updates before the async save so rapid
  /// consecutive taps build on each other instead of overwriting.
  Future<void> _quick(Idea next) async {
    setState(() => _idea = next);
    await AppScope.of(context).store.save(next);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this idea?'),
        content: const Text('This cannot be undone. Consider moving it to Shelved instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _deleted = true;
    await AppScope.of(context).store.remove(_idea.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onPop(bool didPop, Object? _) async {
    if (didPop) return;
    final error = await _persist();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        appBar: AppBar(actions: _actions()),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: _fields(),
        ),
      ),
    );
  }

  List<Widget> _actions() => [
        IconButton(
          tooltip: _idea.starred ? 'Unstar' : 'Star',
          icon: Icon(
            _idea.starred ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.amber,
          ),
          onPressed: () => _quick(_idea.copyWith(starred: !_idea.starred)),
        ),
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () async {
            await _persist();
            await SharePlus.instance.share(ShareParams(text: _idea.shareText()));
          },
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _delete,
        ),
      ];

  List<Widget> _fields() => [
        TextField(
          key: const Key('detail-title'),
              autocorrect: false,
              enableSuggestions: false,
          controller: _title,
          maxLength: Idea.maxTitle,
          maxLines: null,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 18),
        const FieldLabel('Stage'),
        StagePicker(selected: _idea.stage, onChanged: (s) => _quick(_idea.copyWith(stage: s))),
        const SizedBox(height: 18),
        const FieldLabel('Kind'),
        ChoiceRow<IdeaKind>(
          values: IdeaKind.values,
          selected: _idea.kind,
          label: (k) => k.label,
          onChanged: (k) => _quick(_idea.copyWith(kind: k)),
        ),
        const SizedBox(height: 18),
        const FieldLabel('Gut feel'),
        ChoiceRow<GutFeel>(
          values: GutFeel.values,
          selected: _idea.gut,
          label: (g) => g.label,
          onChanged: (g) => _quick(_idea.copyWith(gut: g)),
        ),
        const SizedBox(height: 18),
        const FieldLabel('Notes'),
        TextField(controller: _notes, autocorrect: false, enableSuggestions: false, minLines: 4, maxLines: null, maxLength: Idea.maxNotes,
            decoration: const InputDecoration(counterText: '')),
        const SizedBox(height: 18),
        const FieldLabel('Next step'),
        TextField(controller: _next, autocorrect: false, enableSuggestions: false, maxLines: null, maxLength: Idea.maxNextStep,
            decoration: const InputDecoration(hintText: 'Smallest thing to move it forward', counterText: '')),
        const SizedBox(height: 18),
        const FieldLabel('Tags'),
        TextField(controller: _tags, autocorrect: false,
            decoration: const InputDecoration(hintText: 'comma, separated')),
      ];
}
