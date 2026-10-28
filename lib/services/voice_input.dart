import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceStatus { idle, listening, unavailable, denied, error }

/// Speech-to-text boundary, abstracted for tests.
abstract interface class VoiceInput {
  /// Prepares recognition and asks for mic/speech permission on first use.
  Future<VoiceStatus> prepare();

  /// Streams the running transcript to [onText]; [onDone] fires when the
  /// session ends (silence, stop, or error) with the final status.
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<VoiceStatus> onDone,
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
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
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
