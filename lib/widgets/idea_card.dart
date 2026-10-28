import 'package:flutter/material.dart';

import '../models/idea.dart';
import '../theme.dart';

String relativeTime(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).toUtc().difference(t.toUtc());
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  if (d.inDays < 365) return '${(d.inDays / 7).floor()}w';
  return '${(d.inDays / 365).floor()}y';
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.bg, required this.fg, this.bold = false});

  final String label;
  final Color bg;
  final Color fg;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: bold ? FontWeight.w600 : null),
      ),
    );
  }
}

class IdeaCard extends StatelessWidget {
  const IdeaCard({super.key, required this.idea, required this.onTap});

  final Idea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.kind(idea.kind);
    final snippet = idea.notes.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idea.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                  if (idea.starred)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.star_rounded, size: 18, color: AppColors.amber, semanticLabel: 'Starred'),
                    ),
                ],
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Pill(label: idea.kind.label, bg: bg, fg: fg, bold: true),
                  const SizedBox(width: 8),
                  Pill(label: idea.stage.label, bg: const Color(0xFF22252D), fg: const Color(0xFFC9CDD5)),
                  const Spacer(),
                  Text(
                    relativeTime(idea.updatedAt),
                    style: const TextStyle(fontFamily: monoFamily, fontSize: 12, color: AppColors.textFaint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
