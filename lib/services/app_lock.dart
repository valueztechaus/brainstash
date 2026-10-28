import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../data/key_store.dart';

/// Biometric / passcode authenticator, abstracted for tests.
typedef Authenticator = Future<bool> Function(String reason);

/// Whether the device has Face ID / Touch ID / a passcode configured.
typedef SupportCheck = Future<bool> Function();

Future<bool> _deviceAuth(String reason) =>
    LocalAuthentication().authenticate(localizedReason: reason);

Future<bool> _deviceSupported() => LocalAuthentication().isDeviceSupported();

/// Optional Face ID / passcode lock. When enabled the app locks on launch and
/// whenever it goes to the background.
class AppLock extends ChangeNotifier {
  AppLock({required KeyStore keyStore, Authenticator? authenticator, SupportCheck? supported})
      : _keys = keyStore,
        _auth = authenticator ?? _deviceAuth,
        _supported = supported ?? _deviceSupported;

  static const flag = 'app_lock_enabled';
  final KeyStore _keys;
  final Authenticator _auth;
  final SupportCheck _supported;
  bool _enabled = false;
  bool _locked = false;
  bool _busy = false;
  bool _lastAttemptFailed = false;

  bool get enabled => _enabled;
  bool get locked => _locked;

  Future<void> init() async {
    try {
      _enabled = await _keys.readFlag(flag);
    } on Object catch (e) {
      // Fail closed: if the setting can't be read, require auth.
      debugPrint('Lock flag unreadable: $e');
      _enabled = true;
    }
    _locked = _enabled;
    notifyListeners();
  }

  void onBackgrounded() {
    _lastAttemptFailed = false;
    if (_enabled && !_locked) {
      _locked = true;
      notifyListeners();
    }
  }

  /// Called on resume. Skips the automatic prompt after a cancelled attempt
  /// so the system dialog can't loop; the Unlock button still works.
  Future<void> autoUnlock() async {
    if (!_lastAttemptFailed) await unlock();
  }

  Future<bool> unlock() async {
    if (!_locked) return true;
    if (_busy) return false;
    _busy = true;
    try {
      // If the passcode was removed after enabling the lock, iOS offers no way
      // to authenticate; the device itself is unprotected, so don't brick the app.
      final ok = !await _supported() || await _auth('Unlock your ideas');
      _lastAttemptFailed = !ok;
      if (ok) {
        _locked = false;
        notifyListeners();
      }
      return ok;
    } on Object catch (e) {
      debugPrint('Unlock failed: $e');
      _lastAttemptFailed = true;
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Turning the lock on or off requires a successful auth, so a user can't
  /// enable it on a device without a passcode, and a passer-by can't disable it.
  Future<bool> setEnabled({required bool value}) async {
    final ok = await _safeAuth(value ? 'Confirm to turn on app lock' : 'Confirm to turn off app lock');
    if (!ok) return false;
    _enabled = value;
    await _keys.writeFlag(flag, value: value);
    notifyListeners();
    return true;
  }

  /// Re-authenticate before sensitive actions (export, delete all) when the
  /// lock is enabled.
  Future<bool> confirmSensitive(String reason) async => !_enabled || await _safeAuth(reason);

  Future<bool> _safeAuth(String reason) async {
    try {
      return await _supported() && await _auth(reason);
    } on Object catch (e) {
      debugPrint('Auth failed: $e');
      return false;
    }
  }
}
