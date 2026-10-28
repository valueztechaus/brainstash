import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/attachment.dart';
import '../services/attachment_share.dart';
import '../theme.dart';
import '../widgets/attachment_strip.dart';

/// Full-screen photo (pinch to zoom) or file summary, with share and remove.
/// Pops `true` when the user removes the attachment.
class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({super.key, required this.attachment, required this.load});

  final Attachment attachment;
  final AttachmentLoader load;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late final Future<Uint8List?> _bytes = widget.load(widget.attachment.id);

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _bytes;
      if (bytes == null) throw StateError('missing');
      await shareAttachment(widget.attachment, bytes);
    } on Object catch (e) {
      debugPrint('Share failed: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Could not open that file.')));
    }
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove attachment?'),
        content: const Text('It will be deleted from Brainstash. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            key: const Key('attachment-remove-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            key: const Key('attachment-share'),
            tooltip: 'Open or share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _share,
          ),
          IconButton(
            key: const Key('attachment-remove'),
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _remove,
          ),
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snap.data;
          if (bytes == null) {
            return const Center(child: Text('This attachment could not be read.'));
          }
          if (a.kind == AttachmentKind.image) {
            return InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.memory(bytes,
                    errorBuilder: (_, _, _) => const Text("This image can't be shown. Use share to open it.")),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 64, color: AppColors.amber),
                  const SizedBox(height: 16),
                  Text(a.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(formatBytes(a.size), style: const TextStyle(fontFamily: monoFamily, color: AppColors.textFaint)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open or share'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
