import 'package:flutter/material.dart';

import '../models/idea.dart';
import '../theme.dart';

class StagePicker extends StatelessWidget {
  const StagePicker({super.key, required this.selected, required this.onChanged});

  final IdeaStage selected;
  final ValueChanged<IdeaStage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in IdeaStage.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _StageTile(stage: s, on: s == selected, onTap: () => onChanged(s)),
            ),
          ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.on, required this.onTap});

  final IdeaStage stage;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = on ? AppColors.amber : AppColors.textMuted;
    return Semantics(
      selected: on,
      button: true,
      label: 'Stage ${stage.label}',
      excludeSemantics: true,
      child: Material(
        color: on ? AppColors.amberTint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: on ? AppColors.amber : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? AppColors.amber : const Color(0xFF3A3F4A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stage.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
