import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';

/// Prefix for decrypted share copies in tmp; swept at startup in case the app
/// was killed mid-share.
const shareDirPrefix = 'brainstash-share-';

/// Hands a decrypted copy of an attachment to the iOS share sheet (open in,
/// save to Files, AirDrop…) and deletes the copy afterwards.
Future<void> shareAttachment(Attachment a, Uint8List bytes) async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/$shareDirPrefix${const Uuid().v4()}');
  try {
    await dir.create();
    final file = File('${dir.path}/${Attachment.safeName(a.name)}');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } finally {
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on Object catch (e) {
      debugPrint('Share cleanup failed: $e');
    }
  }
}
