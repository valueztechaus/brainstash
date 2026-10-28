# Project status — Brainstash

_Last updated: 28 October 2026, 16:35 AEDT. Paused by the owner; everything below is committed._

## Where things stand

| Area | State |
|---|---|
| App | Feature-complete for v1.0.0+1: capture, kinds/stages, search (text + voice), Face ID lock, on-device voice with hands-free "save the idea", photo/file attachments, export, delete-all |
| Tests | 95 passing (`flutter test`); integration test in `integration_test/` (needs an empty simulator store) |
| Security | gitleaks, osv-scanner, semgrep clean (`tools/security_scan.sh`); MobSF last run on v1 IPA (`tools/mobsf_scan.sh`) — re-run before App Store submission because voice and attachments added plugins |
| CI | GitHub Actions on every push to `main` (analyze, test, scans) |
| Devices | Installed on the owner's iPhone (release build, team `MSU6JUWVPP`) and the iPhone 18 Pro Max simulator |
| App Store | Not submitted. Checklist in `docs/APP_STORE.md`; bundle id `com.valueztech.brainstashapp` |
| Article | `docs/ARTICLE.md` (text) and `docs/article/brainstash-article.html` (branded page; draft also at https://claude.ai/artifact/NsEaF6RpzLcGvahnzNKNbg, private) |

## Where everything is recorded

| What | File |
|---|---|
| Design spec (incl. voice, search, attachments) | `docs/superpowers/specs/2026-10-28-brainstash-design.md` |
| Implementation plan and increments | `docs/superpowers/plans/2026-10-28-brainstash-v1.md` |
| Every decision with reason and rejected alternative (D1–D41) | `docs/DECISIONS.md` |
| Security controls, scan results, accepted risks | `security/REPORT.md`, `security/reports/` |
| Token usage for the build | `docs/TOKENS.md` (regenerate with `tools/token_report.py`) |
| Claude Design canvas source | `docs/design/` (live canvas: https://claude.ai/artifact/JPToRXikpw3gmVjTNx3BRj, private) |
| App Store submission steps | `docs/APP_STORE.md` |

## Resume checklist

1. `flutter pub get && flutter test` — expect 95 passing.
2. Simulator: `flutter build ios --simulator --debug -t lib/main.dart`, then install `build/ios/iphonesimulator/Runner.app`. Don't leave the `flutter drive` test build installed — it doesn't respond to taps.
3. iPhone (cable, unlocked): `flutter build ios --config-only --release`, then
   `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination "id=<UDID>" -allowProvisioningUpdates -derivedDataPath build/ios-device build`
   and `xcrun devicectl device install app --device <UDID> build/ios-device/Build/Products/Release-iphoneos/Runner.app`.
4. Before App Store: re-run MobSF on a fresh release IPA, regenerate screenshots (current ones predate the mic and attachments), then follow `docs/APP_STORE.md`.

## Open items (optional)

- Regenerate App Store / README screenshots to show voice and attachments.
- Re-run the independent security review on Opus (D29) and MobSF on the current build.
- Possible later features: export including attachments (zip), Android build, iCloud-free sync.
