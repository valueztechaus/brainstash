import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/attachment.dart';
import '../services/attachment_picker.dart';
import '../theme.dart';

typedef AttachmentLoader = Future<Uint8List?> Function(String attachmentId);

/// Thumbnails for an idea's photos and files plus an "add" tile that offers
/// camera, photo library or Files.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.items,
    required this.load,
    required this.onAdd,
    required this.onOpen,
    this.busy = false,
  });

  final List<Attachment> items;
  final AttachmentLoader load;
  final ValueChanged<AttachmentSource> onAdd;
  final ValueChanged<Attachment> onOpen;
  final bool busy;

  static const _tile = 76.0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final a in items)
          _Tile(
            key: ValueKey('attachment-${a.id}'),
            attachment: a,
            load: load,
            onTap: () => onOpen(a),
          ),
        if (items.length < Attachment.maxPerIdea)
          Semantics(
            button: true,
            label: 'Attach photo or file',
            excludeSemantics: true,
            child: InkWell(
              key: const Key('attach-add'),
              borderRadius: BorderRadius.circular(12),
              onTap: busy ? null : () => _chooseSource(context),
              child: Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: busy
                    ? const Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.add_photo_alternate_outlined, color: AppColors.amber),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<AttachmentSource>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('attach-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, AttachmentSource.camera),
            ),
            ListTile(
              key: const Key('attach-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Photos'),
              onTap: () => Navigator.pop(ctx, AttachmentSource.gallery),
            ),
            ListTile(
              key: const Key('attach-files'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('Choose a file'),
              onTap: () => Navigator.pop(ctx, AttachmentSource.files),
            ),
          ],
        ),
      ),
    );
    if (source != null) onAdd(source);
  }
}

class _Tile extends StatefulWidget {
  const _Tile({super.key, required this.attachment, required this.load, required this.onTap});

  final Attachment attachment;
  final AttachmentLoader load;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.kind == AttachmentKind.image) _bytes = widget.load(widget.attachment.id);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    return Semantics(
      button: true,
      label: '${a.kind == AttachmentKind.image ? 'Photo' : 'File'} ${a.name}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: AttachmentStrip._tile,
            height: AttachmentStrip._tile,
            color: AppColors.surfaceHigh,
            child: a.kind == AttachmentKind.image ? _image() : _file(a),
          ),
        ),
      ),
    );
  }

  Widget _image() => FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snap) {
          final b = snap.data;
          if (b == null) {
            return Icon(snap.connectionState == ConnectionState.done ? Icons.broken_image_outlined : Icons.image_outlined,
                color: AppColors.textFaint);
          }
          return Image.memory(b, fit: BoxFit.cover, cacheWidth: 228, gaplessPlayback: true,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: AppColors.textFaint));
        },
      );

  Widget _file(Attachment a) {
    final dot = a.name.lastIndexOf('.');
    final ext = dot > 0 && a.name.length - dot <= 6 ? a.name.substring(dot + 1).toUpperCase() : 'FILE';
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, color: AppColors.amber, size: 22),
          const SizedBox(height: 2),
          Text(ext, style: const TextStyle(fontFamily: monoFamily, fontSize: 10, color: AppColors.textMuted)),
          Text(a.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
