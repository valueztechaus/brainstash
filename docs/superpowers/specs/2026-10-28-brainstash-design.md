# Brainstash — Design Spec

**Date:** 2026-10-28
**Status:** Approved (owner opted out of Q&A: "do it in one shot, take your best judgement")
**Visual design:** Claude Design canvas — https://claude.ai/artifact/JPToRXikpw3gmVjTNx3BRj (private to owner)

## Intent

A personal iOS app to capture "brain dump" ideas the moment they arrive — products to
build, services to offer, problems worth solving, anything — and review them later to
decide which to take up as a project. Released as a public open-source GitHub project so
others can use and fork it.

## Goals

1. **Capture in under 5 seconds.** One tap from launch to typing. Only the title is required.
2. **Review and triage.** Search, filter by kind, star, and move ideas through stages:
   `Spark → Exploring → Ready → Building → Shelved`.
3. **Private by default.** Data never leaves the device unless the user exports it.
4. **Ship-ready.** App Store icon, bundle id, privacy manifest, security scan reports.

## Non-goals (v1)

- Cloud sync, accounts, collaboration.
- AI summarisation / auto-tagging.
- Android build (Flutter makes it possible later; not tested now).
- ~~Voice capture~~ — added 2026-10-28 at owner's request, see *Voice capture* below.

## Anti-goals (failure even if it "works")

- Any network call, analytics, or third-party SDK that phones home.
- Capture flow that forces the user to fill in categories before saving.
- Plain-text storage of ideas on disk.

## Data model

| Field      | Type                         | Notes                                   |
|------------|------------------------------|-----------------------------------------|
| id         | UUID v4 string               |                                         |
| title      | string, 1–200 chars, trimmed | required                                |
| notes      | string, ≤ 20 000 chars       | free text brain dump                    |
| kind       | product/service/problem/other| default `other`                         |
| stage      | spark/exploring/ready/building/shelved | default `spark`              |
| gut        | meh/good/mustBuild           | default `good`                          |
| nextStep   | string, ≤ 500 chars          | optional                                |
| tags       | list<string>, ≤ 20, each ≤ 32, lower-case, de-duped |                  |
| starred    | bool                         |                                         |
| createdAt / updatedAt | DateTime UTC      |                                         |

## Screens (match design canvas)

1. **Inbox** — title, search, kind filter chips with counts, stage filter, idea cards
   (title, snippet, kind tag, stage, relative time, star), amber FAB to capture.
2. **Quick capture** (modal sheet) — Title, "Dump it here" notes, Kind segmented, Gut feel,
   Tags. Save enabled once title is non-empty.
3. **Idea detail** — edit all fields, stage picker, next step, star, share (plain text via
   iOS share sheet), delete with confirm.
4. **Settings** — Face ID / passcode lock toggle, export all (JSON via share sheet),
   delete all data, about/licence.

## Voice capture (added 2026-10-28)

- Mic button on the inbox (above +) opens the capture sheet already listening; mic toggle also
  inside the sheet next to "Dump it here".
- Live transcript streams into notes (appended after any typed notes). If the title was empty when
  dictation started, it is set to the first sentence (capitalised, ≤ 60 chars).
- **On-device only:** `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`
  (`speech_to_text` `onDevice: true`). No server fallback. Audio is not recorded or stored.
- Clear messages for permission denied / on-device unavailable / nothing heard.
- **Hands-free save (added 2026-10-28):** dictation waits through up to 30 s of silence (5 min max) so the
  user can think. Saying a save command at the end — “save the idea”, “save this idea”, “save my idea”,
  “that's it, save it”, “done, save”, “save it now” — strips the command, saves and closes the sheet with a
  haptic tap. Bare “save it” is not a command because it occurs naturally in idea descriptions. Command
  with no idea spoken → prompt, no save. Silence timeout → “Paused. Tap Save, or the mic to keep going.”
- Cancelled if the sheet closes.

## Search (updated 2026-10-28)

- Text field plus mic. Voice search listens up to 15 s, stops after 2 s of silence, and strips lead-ins
  (“search for”, “find my ideas about”, “show me”).
- Query split into words; filler words (a, the, for, about…) dropped; light suffix stemming
  (“walking” → “walk”); every remaining word must appear somewhere in title, notes, next step, tags,
  kind label or stage label, in any order. Clear (×) button resets.

## Security design

- **Encryption at rest:** Hive CE box encrypted with AES-256 (HiveAesCipher). 256-bit key
  generated with `Random.secure()` on first launch, stored in iOS Keychain via
  `flutter_secure_storage` with `KeychainAccessibility.first_unlock_this_device`
  (never synced to iCloud, never restored to another device).
- **iOS Data Protection:** `NSFileProtectionComplete` entitlement on the app container.
- **Optional app lock:** `local_auth` (Face ID / Touch ID / device passcode). Lock again
  when app goes to background.
- **App switcher privacy:** content obscured when app is inactive.
- **No network:** no `INTERNET`-using packages; fonts bundled; ATS left at defaults.
- **Input validation:** model enforces length limits and sanitises tags.
- **Automated security testing:** gitleaks (secrets), osv-scanner (dependency CVEs),
  semgrep (SAST), MobSF (mobile static analysis of the built app). Reports in `security/`.

## Tech

Flutter 3.47 / Dart, iOS 13+, Material 3 dark theme with Fira Sans + Fira Code bundled.
State: `ChangeNotifier` (no extra state-management dependency). Tests: `flutter_test`.

## Left to the builder

Exact spacing/animation, empty-state copy, error copy.
