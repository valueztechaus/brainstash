# Brainstash v1 — Implementation Plan

**Spec:** `docs/superpowers/specs/2026-10-28-brainstash-design.md`
**Goal:** Installable, secure iOS app tested in the simulator, ready for App Store submission
and public GitHub release.

## Tasks

| # | Task | Verify | Status |
|---|------|--------|--------|
| 1 | Design screens + icon in Claude Design | Canvas published | ✅ |
| 2 | Scaffold Flutter project, deps pinned, fonts bundled, icon generated | `flutter pub get` | ✅ |
| 3 | `Idea` model + enums + validation (TDD) | `test/models/idea_test.dart` | ✅ |
| 4 | `IdeaRepository` interface, in-memory + encrypted Hive impl, Keychain key store | `test/data/` | ✅ |
| 5 | `IdeaStore` (ChangeNotifier): CRUD, search, kind/stage filter, counts, sort (TDD) | `test/state/idea_store_test.dart` | ✅ |
| 6 | Theme (dark, Fira, amber) | visual | ✅ |
| 7 | Inbox screen + idea card + FAB | widget test | ✅ |
| 8 | Quick-capture sheet | widget test: save disabled until title | ✅ |
| 9 | Detail screen: edit, stage, star, share, delete | widget test | ✅ |
| 10 | Settings: app lock, export JSON, delete all | manual + unit | ✅ |
| 11 | App lock gate + privacy blur on background | unit/widget tests + simulator | ✅ |
| 12 | iOS hardening: Info.plist strings, file protection, privacy manifest, display name | build | ✅ |
| 13 | Security scans: gitleaks, osv-scanner, semgrep, MobSF; fix findings | `security/REPORT.md` | ✅ |
| 14 | `flutter analyze` clean, all tests pass | CI script | ✅ |
| 15 | Build + run on iOS simulator, screenshots | `docs/screenshots/` | ✅ |
| 16 | README, SECURITY, CONTRIBUTING, LICENSE, App Store submission guide | review | ✅ |
| 17 | Token report | `docs/TOKENS.md` | ✅ |
| 18 | Publish public GitHub repo | URL | ✅ https://github.com/valueztechaus/brainstash |

## Post-v1 increments (all ✅, 28 Oct 2026)

| # | Increment | Commit |
|---|---|---|
| 19 | On-device voice capture | `934d60a` |
| 20 | Bundle id `com.valueztech.brainstashapp`, team signing, installed on physical iPhone | `d04b880` |
| 21 | Hands-free "save the idea" + voice/text search | `db31c81` |
| 22 | Photo and file attachments (encrypted) | `6103159` |
| 23 | Valueztech branding + website article | `7a7c35e` |
| 24 | Project handover: design sources, article page, STATUS.md | this commit |
