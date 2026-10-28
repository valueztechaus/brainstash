# Security Report — Brainstash v1.0.0

_Date: 2026-10-28 · Re-run anytime with `./tools/security_scan.sh`_

## Threat model (short)

Local-only app, no network, no backend, no accounts. Assets: the user's idea text.
Threats: someone holding an unlocked/locked phone, backups/forensics of app files, app-switcher
snapshots, keyboard learning caches, leaked secrets in the public repo, vulnerable dependencies.

## Controls

| Control | Implementation |
|---|---|
| Encryption at rest | Hive CE + AES-256 (`HiveAesCipher`), key = 32 bytes `Random.secure()` |
| Key storage | iOS Keychain, `first_unlock_this_device` (no iCloud sync, no migration) |
| File protection | `NSFileProtectionComplete` entitlement + directory attribute |
| Backups | Store directory `isExcludedFromBackup` |
| App lock | Optional Face ID/Touch ID/passcode; re-lock on background; fail closed |
| App switcher | Native cover on `UIScene.willDeactivate` + Flutter cover |
| Keyboard | Autocorrect/suggestions disabled on idea fields |
| Voice | On-device speech recognition only (`requiresOnDeviceRecognition`); audio never stored or transmitted; mic/speech permission strings explain this |
| Network | None. No ATS exceptions. Fonts bundled |
| Input validation | Length caps & tag sanitising in `Idea` model (all construction paths) |
| Export | Re-auth when locked; temp file deleted after share + swept at launch |
| Privacy manifest | No tracking, no collected data |

## Automated scans

| Tool | Scope | Result |
|---|---|---|
| **gitleaks 8.30** | Working tree + git history | ✅ No leaks |
| **osv-scanner 2.7** | `pubspec.lock` (86 packages) | ✅ No known vulnerabilities |
| **semgrep 1.182** | `p/secrets`, `p/owasp-top-ten`, `p/swift`, `r/dart` — 56 files | ✅ 0 findings |
| **flutter analyze** | strict-casts, strict-raw-types | ✅ No issues |
| **MobSF (latest, Docker)** | Release `Runner.app` packaged as IPA | ✅ **0 high**, 0 trackers, score 64/100 (see below) |

Raw outputs: `security/reports/`.

### MobSF triage

| Warning | Verdict |
|---|---|
| Debug symbols not stripped | **Fixed** — Release config now sets `DEPLOYMENT_POSTPROCESSING`, `STRIP_INSTALLED_PRODUCT`, `STRIP_STYLE=all` (dSYM kept separately). Score 61 → 64. |
| "May contain hardcoded secrets" | **False positive** — matches are hex lookup tables and Pigeon codec class names in plugin code. gitleaks + semgrep confirm no secrets. |
| `@rpath` set | **Accepted** — required to load the embedded `Flutter.framework`. |
| malloc / "insecure API" usage | **Accepted** — inside the Flutter engine (C++), not app code. |
| Logging function | **Info** — `debugPrint` of error types only; no idea content is logged. |

Binary hardening confirmed: PIE ✅, stack canary ✅, ARC ✅.

## On-device verification (iPhone 18 Pro Max simulator, iOS 27.1)

- Store file `Library/Application Support/brainstash/ideas_v1.hive` (2.8 KB) contains **0** plaintext
  matches for the idea text that was entered.
- Directory carries `com.apple.metadata:com_apple_backup_excludeItem` (= excluded from backup).
- Kill + relaunch: all ideas, stars and stages persist (key correctly read back from Keychain).
- End-to-end integration test (`integration_test/app_test.dart`) passes against the real Keychain + encrypted store.

## Manual / AI security review

An independent Claude security-review agent reviewed all Dart, Swift and plist files.
Result: **0 critical, 1 high, 4 medium, 5 low.** All high and medium items were fixed
(with tests), plus 4 of the low ones:

| Sev | Finding | Fix |
|---|---|---|
| High | Missing/invalid Keychain key silently replaced → data orphaned (backup restore) | Key only created when no store exists; otherwise "erase and start fresh" screen. Store excluded from backups. Tests: `hive_repository_test.dart` |
| Medium | App-switcher cover relied on Flutter frame timing | Native cover in `SceneDelegate.swift` |
| Medium | Keyboard learning on idea fields | `autocorrect: false`, `enableSuggestions: false` |
| Medium | Lockout if passcode removed after enabling lock | Unlock allowed when device auth unavailable |
| Medium | Face ID prompt loop on resume after cancel | No auto-prompt after failed attempt (test) |
| Low | Lock flag failed open on Keychain read error | Fails closed (test) |
| Low | Export temp file could persist if killed; no re-auth | Startup sweep + `confirmSensitive` before export/delete-all |
| Low | Raw exception text shown to user | Generic messages |
| Low | Navigator disposed on lock (drafts lost) | Kept mounted under cover |
| Low | Corrupt records skipped silently | Now logged with count (accepted: not surfaced in UI) |

## Supply chain

- All pub dependencies pinned to exact versions; `pubspec.lock` committed and scanned by osv-scanner.
- semgrep flagged mutable GitHub Action tags in CI → **fixed**: every action pinned to a full commit SHA;
  semgrep version pinned.
- gitleaks allowlist covers only generated scanner output (`security/reports/`, `build/`).

## Accepted risks

- Plaintext exists in memory while the app is unlocked (inherent).
- Export JSON is unencrypted by design — the user chooses where it goes.
- No backups of the encrypted store: the user must export to keep a copy.
