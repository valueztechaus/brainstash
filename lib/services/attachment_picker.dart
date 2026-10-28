import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/attachment.dart';

enum AttachmentSource { camera, gallery, files }

typedef PickedAttachment = ({String name, AttachmentKind kind, Uint8List bytes});

class AttachmentPickError implements Exception {
  const AttachmentPickError(this.message);
  final String message;
}

/// Camera / photo library / Files boundary, abstracted for tests.
abstract interface class AttachmentPicker {
  /// Returns null when the user cancels.
  Future<PickedAttachment?> pick(AttachmentSource source);
}

class DeviceAttachmentPicker implements AttachmentPicker {
  final _images = ImagePicker();

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    try {
      return source == AttachmentSource.files ? await _pickFile() : await _pickImage(source);
    } on AttachmentPickError {
      rethrow;
    } on PlatformException catch (e) {
      debugPrint('Pick failed: ${e.code}');
      throw AttachmentPickError(e.code.contains('access_denied') || e.code.contains('denied')
          ? 'Allow ${source == AttachmentSource.camera ? 'Camera' : 'Photos'} access for Brainstash in iOS Settings.'
          : "Couldn't open that. Please try again.");
    } on Object catch (e) {
      debugPrint('Pick failed: $e');
      throw const AttachmentPickError("Couldn't open that. Please try again.");
    }
  }

  Future<PickedAttachment?> _pickImage(AttachmentSource source) async {
    // Re-encoded at <=2048 px without full metadata: smaller, and drops GPS EXIF.
    final x = await _images.pickImage(
      source: source == AttachmentSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    try {
      final bytes = await x.readAsBytes();
      final stamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
      return (name: 'Photo $stamp.jpg', kind: AttachmentKind.image, bytes: bytes);
    } finally {
      await _deleteQuietly(x.path);
    }
  }

  Future<PickedAttachment?> _pickFile() async {
    final f = await FilePicker.pickFile();
    if (f == null) return null;
    try {
      final size = await f.length();
      if (size != null && size > Attachment.maxBytes) {
        throw const AttachmentPickError('Attachments must be 15 MB or smaller.');
      }
      final bytes = await f.readAsBytes();
      final ext = (f.extension ?? '').toLowerCase();
      final isImage = const {'jpg', 'jpeg', 'png', 'heic', 'gif', 'webp'}.contains(ext);
      return (name: f.name, kind: isImage ? AttachmentKind.image : AttachmentKind.file, bytes: bytes);
    } finally {
      // The picker copies the file into tmp; the encrypted copy is the only one we keep.
      await FilePicker.clearTemporaryFiles();
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } on Object catch (e) {
      debugPrint('Temp cleanup failed: $e');
    }
  }
}
