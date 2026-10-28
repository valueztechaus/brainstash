import 'package:flutter/material.dart';

import 'screens/inbox_screen.dart';
import 'services/app_lock.dart';
import 'services/attachment_picker.dart';
import 'services/voice_input.dart';
import 'state/idea_store.dart';
import 'theme.dart';
import 'widgets/brand_mark.dart';

/// Gives every screen access to the store and lock without a DI package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.lock,
    required this.voice,
    required this.picker,
    required super.child,
  });

  final IdeaStore store;
  final AppLock lock;
  final VoiceInput voice;
  final AttachmentPicker picker;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      old.store != store || old.lock != lock || old.voice != voice || old.picker != picker;
}

class BrainstashApp extends StatelessWidget {
  const BrainstashApp({
    super.key,
    required this.store,
    required this.lock,
    required this.voice,
    required this.picker,
  });

  final IdeaStore store;
  final AppLock lock;
  final VoiceInput voice;
  final AttachmentPicker picker;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      lock: lock,
      voice: voice,
      picker: picker,
      child: MaterialApp(
        title: 'Brainstash',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => LockGate(lock: lock, child: child!),
        home: const InboxScreen(),
      ),
    );
  }
}

/// Covers content in the app switcher and enforces the optional app lock.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.lock, required this.child});

  final AppLock lock;
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.lock.unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        setState(() => _obscured = true);
      case AppLifecycleState.paused:
        setState(() => _obscured = true);
        widget.lock.onBackgrounded();
      case AppLifecycleState.resumed:
        setState(() => _obscured = false);
        widget.lock.autoUnlock();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.lock,
      builder: (context, _) {
        final locked = widget.lock.locked;
        // The app stays mounted under the cover so open drafts survive a lock,
        // but it is hidden from touch, accessibility and animation.
        return Stack(
          children: [
            IgnorePointer(
              ignoring: locked,
              child: ExcludeSemantics(
                excluding: locked,
                child: TickerMode(enabled: !locked, child: widget.child),
              ),
            ),
            if (locked || _obscured)
              _Cover(locked: locked && !_obscured, onUnlock: widget.lock.unlock),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.locked, required this.onUnlock});

  final bool locked;
  final Future<bool> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 96),
            const SizedBox(height: 24),
            if (locked)
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                onPressed: onUnlock,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock'),
              ),
          ],
        ),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message, this.onReset});

  final String message;
  final Future<void> Function()? onReset;

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase and start fresh?'),
        content: const Text('Your existing ideas will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await onReset!();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(size: 88),
                const SizedBox(height: 24),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
                if (onReset != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _confirmReset(context),
                    child: const Text('Erase and start fresh'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
