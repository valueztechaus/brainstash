# App Store Submission Guide

Everything below is prepared except the steps that need your Apple ID (marked 🔑).

## 1. Ready in the repo

| Item | Where | Status |
|---|---|---|
| App icon 1024×1024, opaque PNG | `assets/icon/icon-1024.png` (all sizes generated into `ios/Runner/Assets.xcassets`) | ✅ |
| Bundle id | `com.valueztech.brainstashapp` | ✅ |
| Display name | Brainstash | ✅ |
| Version | `1.0.0 (1)` — from `pubspec.yaml` `version:` | ✅ |
| Face ID usage string | `Info.plist` `NSFaceIDUsageDescription` | ✅ |
| Mic + speech usage strings | `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` | ✅ |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` (see note) | ✅ |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` — no tracking, no data collected | ✅ |
| Data Protection | `Runner.entitlements` → `NSFileProtectionComplete` | ✅ |
| Device family | iPhone only, portrait | ✅ |
| Category | Productivity | ✅ |

**Export compliance note:** the app only uses encryption to protect the user's own data at
rest on the device (AES via Hive, iOS Keychain). That falls under the exemption for
encryption limited to data protection, so `NO` is the usual answer. If Apple asks, answer
"Yes, uses encryption" → "Qualifies for exemption (data protection only)".

## 2. 🔑 One-time setup in App Store Connect

1. https://developer.apple.com/account/resources/identifiers → **+** → App IDs →
   bundle id `com.valueztech.brainstashapp`. Enable **Data Protection** (Complete).
2. https://appstoreconnect.apple.com → My Apps → **+ New App** → iOS, name *Brainstash*
   (pick an alternative if taken), primary language English (AU), bundle id above, SKU `brainstash-001`.

## 3. 🔑 Build and upload

```bash
flutter build ipa --release
open build/ios/archive/Runner.xcarchive   # Xcode Organizer → Distribute App → App Store Connect
```

Or open `ios/Runner.xcworkspace`, set *Signing & Capabilities → Team* to your team, then
Product → Archive → Distribute.

## 4. Store listing (copy ready to paste)

- **Subtitle (30):** Capture ideas. Build later.
- **Promotional text:** Two taps from spark to saved. Private, encrypted, offline.
- **Description:**

  > Brainstash is a private inbox for every idea that pops into your head — products to build,
  > services to offer, problems worth solving.
  >
  > • Capture in seconds: tap +, type a title, done.
  > • Or tap the mic and just talk, then say “save the idea” — hands-free. Speech is recognised on your iPhone, never in the cloud.
  > • Sort ideas by kind: Product, Service, Problem, Other.
  > • Move ideas through stages: Spark, Exploring, Ready, Building, Shelved.
  > • Search by typing or by voice, star your favourites.
  > • Add a "next step" so good ideas keep moving.
  > • Optional Face ID lock.
  >
  > Your ideas never leave your phone. They're encrypted on-device, with no accounts,
  > no analytics and no network access. Open source on GitHub.

- **Keywords (100):** ideas,brain dump,notes,inbox,startup,product,side project,journal,capture,private
- **Support URL:** https://github.com/valueztechaus/brainstash/issues
- **Privacy policy URL:** https://github.com/valueztechaus/brainstash/blob/main/PRIVACY.md
- **App Privacy questionnaire:** "Data Not Collected".
- **Age rating:** 4+.
- **Screenshots:** 6.9" iPhone required — `docs/screenshots/*.png` are 1320×2868 from the
  *iPhone 18 Pro Max* simulator and can be uploaded as-is. Regenerate with `flutter drive` (see README).

## 5. Review notes for Apple

> No login required. All data is stored locally. To test the lock: Settings → Require Face ID
> / passcode (in the simulator use Features → Face ID → Enrolled, then Matching Face).
