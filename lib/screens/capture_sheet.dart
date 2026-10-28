import 'package:flutter/material.dart';

import '../app.dart';
import '../models/idea.dart';
import '../theme.dart';
import '../widgets/choice_row.dart';

Future<void> showCaptureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const CaptureSheet(),
  );
}

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key});

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  IdeaKind _kind = IdeaKind.other;
  GutFeel _gut = GutFeel.good;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final idea = Idea.create(
        title: _title.text,
        notes: _notes.text,
        kind: _kind,
        gut: _gut,
        tags: Idea.parseTags(_tags.text),
      );
      await AppScope.of(context).store.save(idea);
      if (mounted) Navigator.of(context).pop();
    } on IdeaValidationError catch (e) {
      setState(() => _error = e.message);
    } on Object catch (e) {
      debugPrint('Save failed: $e');
      setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 12),
            const FieldLabel('Title'),
            TextField(
              key: const Key('capture-title'),
              autocorrect: false,
              enableSuggestions: false,
              controller: _title,
              autofocus: true,
              maxLength: Idea.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'What sparked?', counterText: ''),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Dump it here'),
            TextField(
              key: const Key('capture-notes'),
              autocorrect: false,
              enableSuggestions: false,
              controller: _notes,
              minLines: 4,
              maxLines: 8,
              maxLength: Idea.maxNotes,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Who is it for? What problem? Why now?',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Kind'),
            ChoiceRow<IdeaKind>(
              values: IdeaKind.values,
              selected: _kind,
              label: (k) => k.label,
              onChanged: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Gut feel'),
            ChoiceRow<GutFeel>(
              values: GutFeel.values,
              selected: _gut,
              label: (g) => g.label,
              onChanged: (g) => setState(() => _gut = g),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Tags'),
            TextField(
              controller: _tags,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'comma, separated'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
        ),
        const Text('New idea', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        TextButton(
          key: const Key('capture-save'),
          onPressed: _canSave ? _save : null,
          child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
