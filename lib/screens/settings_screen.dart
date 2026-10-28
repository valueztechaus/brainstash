import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final scope = AppScope.of(context);
    final store = scope.store;
    final messenger = ScaffoldMessenger.of(context);
    if (!await scope.lock.confirmSensitive('Confirm to export your ideas')) return;
    File? file;
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      file = File('${dir.path}/brainstash-export-$stamp.json');
      await file.writeAsString(store.exportJson(), flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on Object catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Export failed. Please try again.')));
    } finally {
      // The export is plaintext; don't leave it lying around in tmp.
      if (file != null && file.existsSync()) await file.delete();
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final store = AppScope.of(context).store;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all ideas?'),
        content: Text('This permanently erases ${store.total} ideas from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (await AppScope.of(context).lock.confirmSensitive('Confirm to delete all ideas')) {
      await store.clearAll();
    }
  }

  Future<void> _toggleLock(BuildContext context, bool value) async {
    final lock = AppScope.of(context).lock;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await lock.setEnabled(value: value);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not verify Face ID / passcode. Set a device passcode first.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = AppScope.of(context).lock;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListenableBuilder(
            listenable: lock,
            builder: (context, _) => SwitchListTile(
              key: const Key('lock-switch'),
              title: const Text('Require Face ID / passcode'),
              subtitle: const Text('Locks when you leave the app'),
              value: lock.enabled,
              onChanged: (v) => _toggleLock(context, v),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Export all ideas'),
            subtitle: const Text('JSON file via the share sheet (unencrypted)'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('Delete all data', style: TextStyle(color: AppColors.danger)),
            onTap: () => _deleteAll(context),
          ),
          const Divider(),
          const _About(),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const BrandMark(size: 72),
          const SizedBox(height: 12),
          const Text('Brainstash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Dump the spark. Build it later.\n\n'
            'Your ideas are encrypted (AES-256) and never leave this device. '
            'No accounts, no analytics, no network.\n\nOpen source · MIT licence',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 28),
          const Text('Built by', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
          const SizedBox(height: 8),
          // White-plate logo: the brand has no reversed variant for dark backgrounds.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              'assets/brand/valueztech-logo.png',
              key: const Key('valueztech-logo'),
              width: 220,
              semanticLabel: 'Valueztech — Maximising Asset Intelligence',
            ),
          ),
          const SizedBox(height: 8),
          const Text('www.valueztech.com', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
        ],
      ),
    );
  }
}
