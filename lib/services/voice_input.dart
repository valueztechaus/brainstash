import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceStatus { idle, listening, unavailable, denied, error }

/// Speech-to-text boundary, abstracted for tests.
abstract interface class VoiceInput {
  /// Prepares recognition and asks for mic/speech permission on first use.
  Future<VoiceStatus> prepare();

  /// Streams the running transcript to [onText]; [onDone] fires when the
  /// session ends (silence of [pauseFor], [listenFor] elapsed, stop, or
  /// error) with the final status.
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<VoiceStatus> onDone,
    Duration pauseFor,
    Duration listenFor,
  });

  Future<void> stop();
  Future<void> cancel();
}

/// Apple Speech framework via `speech_to_text`, forced on-device: audio is
/// never sent to Apple's servers and never stored. If the device can't
/// recognise on-device, the session errors instead of falling back.
class OnDeviceVoiceInput implements VoiceInput {
  final SpeechToText _speech = SpeechToText();
  ValueChanged<VoiceStatus>? _onDone;
  bool _errored = false;

  @override
  Future<VoiceStatus> prepare() async {
    try {
      final ok = await _speech.initialize(onError: _handleError, onStatus: _handleStatus);
      if (ok) return VoiceStatus.idle;
      return await _speech.hasPermission ? VoiceStatus.unavailable : VoiceStatus.denied;
    } on Object catch (e) {
      debugPrint('Voice init failed: $e');
      return VoiceStatus.unavailable;
    }
  }

  @override
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<VoiceStatus> onDone,
    Duration pauseFor = const Duration(seconds: 4),
    Duration listenFor = const Duration(minutes: 2),
  }) async {
    _onDone = onDone;
    _errored = false;
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        onDevice: true,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        listenFor: listenFor,
        pauseFor: pauseFor,
      ),
    );
  }

  void _handleError(SpeechRecognitionError e) {
    debugPrint('Voice error: ${e.errorMsg}');
    _errored = true;
    _finish(VoiceStatus.error);
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus && !_errored) _finish(VoiceStatus.idle);
  }

  void _finish(VoiceStatus s) {
    final cb = _onDone;
    _onDone = null;
    cb?.call(s);
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

/// First sentence of the transcript, capitalised, max ~60 chars.
String titleFromTranscript(String transcript) {
  final text = transcript.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return '';
  final m = RegExp(r'^(.+?)([.!?])(\s|$)').firstMatch(text);
  var title = m == null ? text : (m.group(2) == '.' ? m.group(1)! : '${m.group(1)}${m.group(2)}');
  const max = 60;
  if (title.length > max) {
    final cut = title.substring(0, max);
    final space = cut.lastIndexOf(' ');
    title = '${(space > 20 ? cut.substring(0, space) : cut).trimRight()}…';
  }
  return title[0].toUpperCase() + title.substring(1);
}

String mergeTranscript(String existing, String transcript) =>
    existing.trim().isEmpty ? transcript : '${existing.trimRight()}\n\n$transcript';

// Spoken "save" commands, only recognised at the very end of the transcript.
// Bare "save it" is excluded because it's common in ordinary idea
// descriptions ("snap a recipe and save it").
final _saveCommand = RegExp(
  r"(?:^|[\s,;:]+)"
  r"(?:(?:ok(?:ay)?|alright|right|please|now)[\s,]+)*"
  r"(?:"
  r"(?:that['’]?s it|that is it|done|finished)[\s,.!]+(?:please[\s,]+)?save(?:\s+(?:it|this|that|(?:the\s+|this\s+)?idea))?"
  r"|save\s+(?:the\s+|this\s+|that\s+|my\s+)?idea"
  r"|save\s+(?:it|this|that)\s+now"
  r")"
  r"(?:\s+(?:now|please))?[\s.!?]*$",
  caseSensitive: false,
);

/// Detects a trailing spoken save command such as "save the idea" and
/// returns the transcript without it.
({String text, bool save}) extractSaveCommand(String transcript) {
  final m = _saveCommand.firstMatch(transcript);
  if (m == null) return (text: transcript, save: false);
  final text = transcript.substring(0, m.start).replaceFirst(RegExp(r'[\s,;:]+$'), '');
  return (text: text, save: true);
}

final _searchLeadIn = RegExp(
  r'^(?:(?:please|can you|could you|search(?: for)?|find(?: me)?|show(?: me)?|look(?: for| up)?|'
  r'any|all|my|the|ideas?|about|for|on|with|related to)\s+)+',
);

/// Turns "Find my ideas about invoices." into "invoices".
String searchQueryFromSpeech(String transcript) {
  final text = transcript.toLowerCase().replaceAll(RegExp(r'[.!?,]'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
  return text.replaceFirst(_searchLeadIn, '');
}
