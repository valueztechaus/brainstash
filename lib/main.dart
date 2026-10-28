import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/idea_repository.dart';
import 'data/key_store.dart';
import 'services/app_lock.dart';
import 'services/attachment_picker.dart';
import 'services/attachment_share.dart';
import 'services/voice_input.dart';
import 'state/idea_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _sweepStaleExports();
  await start();
}

/// Opens storage and runs the app. Re-entered after a user-confirmed reset.
Future<void> start() async {
  final keyStore = SecureKeyStore();
  // Application Support/brainstash: hidden from the Files app and excluded
  // from backups by AppDelegate.swift (the key is device-only).
  final dir = '${(await getApplicationSupportDirectory()).path}/brainstash';
  await Directory(dir).create(recursive: true);
  final IdeaRepository repo;
  try {
    repo = await HiveIdeaRepository.open(directory: dir, keyStore: keyStore);
  } on StoreKeyLostError {
    runApp(StartupErrorApp(
      message: 'The encryption key for your ideas is no longer on this device, '
          'so they cannot be decrypted. You can erase them and start fresh.',
      onReset: () async {
        await HiveIdeaRepository.erase(directory: dir, keyStore: keyStore);
        await start();
      },
    ));
    return;
  } on Object catch (e) {
    debugPrint('Storage open failed: $e');
    runApp(const StartupErrorApp(
      message: 'Brainstash could not open its secure storage. '
          'Unlock your phone and reopen the app.',
    ));
    return;
  }
  final store = IdeaStore(repo);
  final lock = AppLock(keyStore: keyStore);
  await Future.wait([store.load(), lock.init()]);
  runApp(BrainstashApp(
    store: store,
    lock: lock,
    voice: OnDeviceVoiceInput(),
    picker: DeviceAttachmentPicker(),
  ));
}

/// Exports and shared attachments are plaintext; remove any left behind if
/// the app was killed mid-share.
Future<void> _sweepStaleExports() async {
  try {
    final tmp = await getTemporaryDirectory();
    await for (final f in tmp.list()) {
      final name = f.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
      if (f is File && name.startsWith('brainstash-export-')) {
        await f.delete();
      } else if (f is Directory && name.startsWith(shareDirPrefix)) {
        await f.delete(recursive: true);
      }
    }
  } on Object catch (e) {
    debugPrint('Export sweep failed: $e');
  }
}
