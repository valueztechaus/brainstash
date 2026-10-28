import 'package:brainstash/data/key_store.dart';
import 'package:brainstash/services/app_lock.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenKeys extends InMemoryKeyStore {
  @override
  Future<bool> readFlag(String name) async => throw StateError('keychain error');
}

AppLock _lock(KeyStore keys, {required Future<bool> Function() auth, bool supported = true}) =>
    AppLock(keyStore: keys, authenticator: (_) => auth(), supported: () async => supported);

void main() {
  test('should start unlocked when lock disabled', () async {
    final lock = _lock(InMemoryKeyStore(), auth: () async => true);
    await lock.init();
    expect(lock.locked, isFalse);
    lock.onBackgrounded();
    expect(lock.locked, isFalse);
  });

  test('should not enable lock if auth fails', () async {
    final keys = InMemoryKeyStore();
    final lock = _lock(keys, auth: () async => false);
    expect(await lock.setEnabled(value: true), isFalse);
    expect(lock.enabled, isFalse);
    expect(await keys.readFlag(AppLock.flag), isFalse);
  });

  test('should not enable lock on a device without passcode', () async {
    final lock = _lock(InMemoryKeyStore(), auth: () async => true, supported: false);
    expect(await lock.setEnabled(value: true), isFalse);
  });

  test('should require auth to disable lock', () async {
    var allow = true;
    final lock = _lock(InMemoryKeyStore(), auth: () async => allow);
    await lock.setEnabled(value: true);
    allow = false;
    expect(await lock.setEnabled(value: false), isFalse);
    expect(lock.enabled, isTrue);
  });

  test('should lock on background and unlock with auth', () async {
    var allow = true;
    final lock = _lock(InMemoryKeyStore(), auth: () async => allow);
    await lock.setEnabled(value: true);
    lock.onBackgrounded();
    expect(lock.locked, isTrue);
    allow = false;
    expect(await lock.unlock(), isFalse);
    expect(lock.locked, isTrue);
    allow = true;
    expect(await lock.unlock(), isTrue);
    expect(lock.locked, isFalse);
  });

  test('should not auto-prompt again after a cancelled attempt', () async {
    var prompts = 0;
    var allow = true;
    final lock = _lock(InMemoryKeyStore(), auth: () async {
      prompts++;
      return allow;
    });
    await lock.setEnabled(value: true);
    lock.onBackgrounded();
    allow = false;
    await lock.unlock();
    final before = prompts;
    await lock.autoUnlock();
    expect(prompts, before, reason: 'resume after cancel must not loop');
    lock.onBackgrounded();
    await lock.autoUnlock();
    expect(prompts, before + 1, reason: 'a fresh background re-arms auto prompt');
  });

  test('should not brick the app if the passcode was removed', () async {
    var supported = true;
    final keys = InMemoryKeyStore();
    await keys.writeFlag(AppLock.flag, value: true);
    final lock = AppLock(
      keyStore: keys,
      authenticator: (_) async => false,
      supported: () async => supported,
    );
    await lock.init();
    expect(lock.locked, isTrue);
    supported = false;
    expect(await lock.unlock(), isTrue);
  });

  test('should fail closed when the lock flag cannot be read', () async {
    final lock = _lock(_BrokenKeys(), auth: () async => false);
    await lock.init();
    expect(lock.locked, isTrue);
  });

  test('should treat authenticator exceptions as failure', () async {
    final lock = AppLock(
      keyStore: InMemoryKeyStore(),
      authenticator: (_) async => throw StateError('no biometrics'),
      supported: () async => true,
    );
    expect(await lock.setEnabled(value: true), isFalse);
  });

  test('confirmSensitive should pass through when lock disabled', () async {
    final lock = _lock(InMemoryKeyStore(), auth: () async => false);
    expect(await lock.confirmSensitive('x'), isTrue);
  });

  test('should persist enabled flag across restarts', () async {
    final keys = InMemoryKeyStore();
    await _lock(keys, auth: () async => true).setEnabled(value: true);
    final next = _lock(keys, auth: () async => true);
    await next.init();
    expect(next.enabled, isTrue);
    expect(next.locked, isTrue);
  });
}
