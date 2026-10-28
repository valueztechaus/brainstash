import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/idea.dart';
import '../services/voice_input.dart';
import '../theme.dart';
import '../widgets/choice_row.dart';
import '../widgets/voice_button.dart';

Future<void> showCaptureSheet(BuildContext context, {bool voice = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CaptureSheet(startWithVoice: voice),
  );
}

const _voiceMessages = {
  VoiceStatus.denied: 'Allow Microphone and Speech Recognition for Brainstash in iOS Settings.',
  VoiceStatus.unavailable:
      "On-device speech recognition isn't available here. Audio is never sent off your phone, so please type instead.",
  VoiceStatus.error: "Didn't catch that. Tap the mic to try again.",
};

/// How long dictation waits through silence for more words or a spoken
/// "save the idea" before pausing.
const voicePauseFor = Duration(seconds: 30);
const voiceListenFor = Duration(minutes: 5);

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key, this.startWithVoice = false});

  final bool startWithVoice;

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
  bool _listening = false;
  String? _voiceMessage;
  late VoiceInput _voice;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    if (widget.startWithVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toggleVoice());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice = AppScope.of(context).voice;
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _voiceMessage = null);
    final status = await _voice.prepare();
    if (!mounted) return;
    if (status != VoiceStatus.idle) {
      setState(() => _voiceMessage = _voiceMessages[status]);
      return;
    }
    final notesBefore = _notes.text;
    final autoTitle = _title.text.trim().isEmpty;
    var commandHeard = false;
    setState(() => _listening = true);
    await _voice.start(
      pauseFor: voicePauseFor,
      listenFor: voiceListenFor,
      onText: (t) {
        if (!mounted || commandHeard) return;
        final spoken = extractSaveCommand(t);
        _notes.text = mergeTranscript(notesBefore, spoken.text);
        if (autoTitle) _title.text = titleFromTranscript(spoken.text);
        if (spoken.save) {
          commandHeard = true;
          unawaited(_voice.stop());
          unawaited(_saveByVoice());
        }
      },
      onDone: (s) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          if (!commandHeard) {
            _voiceMessage = _voiceMessages[s] ??
                (s == VoiceStatus.idle && _canSave ? 'Paused. Tap Save, or the mic to keep going.' : null);
          }
        });
      },
    );
  }

  Future<void> _saveByVoice() async {
    if (!_canSave) {
      setState(() => _voiceMessage = 'Say your idea first, then "save the idea".');
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    await _save();
  }

  @override
  void dispose() {
    if (_listening) _voice.cancel();
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
              autofocus: !widget.startWithVoice,
              maxLength: Idea.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'What sparked?', counterText: ''),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: FieldLabel('Dump it here')),
                if (_listening)
                  const Padding(
                    padding: EdgeInsets.only(right: 10, bottom: 8),
                    child: Text('Listening… on-device',
                        style: TextStyle(color: AppColors.amber, fontSize: 13)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: VoiceButton(listening: _listening, onPressed: _toggleVoice),
                ),
              ],
            ),
            if (_listening)
              const Padding(
                key: Key('voice-hint'),
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Say “save the idea” when you’re done.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            if (_voiceMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_voiceMessage!,
                    key: const Key('voice-message'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
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
