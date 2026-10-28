import 'package:flutter/material.dart';

import '../theme.dart';

/// Mic toggle with a pulsing ring while listening.
class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key, required this.listening, required this.onPressed});

  final bool listening;
  final VoidCallback onPressed;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(VoiceButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.listening;
    return Semantics(
      button: true,
      label: on ? 'Stop dictation' : 'Dictate with voice',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: on
                ? [BoxShadow(color: AppColors.amber.withValues(alpha: 0.35), spreadRadius: 6 * _pulse.value)]
                : null,
          ),
          child: child,
        ),
        child: IconButton(
          key: const Key('voice-button'),
          onPressed: widget.onPressed,
          style: IconButton.styleFrom(
            backgroundColor: on ? AppColors.amber : AppColors.surfaceHigh,
            foregroundColor: on ? AppColors.amberInk : AppColors.amber,
            minimumSize: const Size.square(44),
          ),
          icon: Icon(on ? Icons.stop_rounded : Icons.mic_rounded),
        ),
      ),
    );
  }
}
