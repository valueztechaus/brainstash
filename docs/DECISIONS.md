# Decision Log

Every significant call made while building Brainstash, with the reason. The owner asked for
an end-to-end build "in one shot" using best judgement, so these are Claude's calls unless
marked otherwise.

| # | Decision | Why | Alternatives rejected |
|---|----------|-----|-----------------------|
| D1 | Name: **Brainstash** | Short, describes "stash your brain dump", no obvious App Store clash for a dev tool name. Rename = change `CFBundleDisplayName` + store listing. | BrainDump (generic, likely taken), IdeaVault |
| D2 | Flutter, iOS only for v1 | Owner's instruction. Android left possible but untested. | — |
| D3 | **Local-only storage, no backend** | Ideas are private IP; no backend = no server attack surface, no hosting cost, no account system. Owner's standard stack (FastAPI etc.) intentionally not used — not needed for a personal offline app. | Firebase, Supabase, CloudKit sync |
| D4 | Hive CE + AES-256, key in Keychain | Encryption at rest with minimal deps and no codegen. Key accessibility `first_unlock_this_device` keeps it off iCloud backups. | sqflite_sqlcipher (heavier native build), drift (codegen) |
| D5 | Optional Face ID lock via `local_auth` | Phones get handed around; default off so first-run capture is instant. | Always-on lock |
| D6 | `ChangeNotifier` state, no Riverpod/Bloc | App is small; fewer deps = smaller supply-chain surface. | Riverpod, Bloc |
| D7 | Bundle Fira Sans/Code fonts, drop `google_fonts` | `google_fonts` downloads at runtime → network call. Owner's standard typography preserved. | google_fonts package |
| D8 | Dark-first UI, amber "spark" accent `#F5B83D` | Matches design canvas; capture often happens at night. | Light theme |
| D9 | Stages: Spark → Exploring → Ready → Building → Shelved | Mirrors how an idea matures into a project; "Shelved" keeps history instead of deleting. | Kanban columns |
| D10 | Only title required on capture | Goal: capture < 5 s. | Required kind/category |
| D11 | Export = JSON via iOS share sheet | Lets user back up / move data without us running a server. | iCloud Drive integration |
| D12 | Security scanners: gitleaks, osv-scanner, semgrep, MobSF | All free, widely used, scriptable; together cover secrets, dependency CVEs, SAST and mobile-binary checks. | Commercial scanners |
| D13 | Bundle id `com.valueztech.brainstashapp` | Owner's company domain. `com.valueztech.brainstash` was already taken in Apple's global App ID namespace, so `app` suffix added. Forks must set their own bundle id and Team in Xcode. | — |
| D14 | MIT licence for public GitHub repo | Most permissive, simplest for others to reuse. | Apache-2.0 |
| D15 | Token usage measured from Claude Code session JSONL logs (`tools/token_report.py`) | Exact per-message usage incl. cache reads/writes and subagents; no estimation. | Manual `/cost` snapshots |
| D16 | Icon: amber spark dropping into a tray, 1024 px, no alpha | App Store requires opaque 1024 icon; concept = "capture the spark". | — |
| D17 | Xcode installed via `mas` (needs owner's sudo) | Xcode was missing; only owner can enter the password. | xcodes CLI (needs Apple ID creds) |
| D18 | Encrypted store **excluded from iCloud/device backups** (native, `AppDelegate.swift`) | Key is device-only, so a restored backup could never be decrypted anyway. Users back up via Export. | Device-syncable key (weaker) |
| D19 | Lost key + existing store → explicit "erase and start fresh" screen, never silent re-key | Security review HIGH finding: silent re-key orphaned data with no explanation. | Silent overwrite |
| D20 | Native privacy cover via `UIScene` notifications | Flutter-drawn cover may miss the app-switcher snapshot. Notifications avoid overriding `FlutterSceneDelegate` lifecycle methods (would break Flutter lifecycle forwarding). | Overriding scene methods |
| D21 | Autocorrect + QuickType suggestions **off** on title, notes, next step, search | Stops idea text feeding the system keyboard dictionary. Trade-off: no autocorrect while capturing. Revisit as a setting if it hurts. | Keep keyboard learning |
| D22 | Lock: auth required to enable **and** disable; re-auth before export / delete-all; no auto re-prompt after cancel; fail closed if flag unreadable; unlock allowed if device passcode removed | Closes lockout, prompt-loop and bypass findings. Passcode removed ⇒ device itself unprotected, bricking the app adds no security. | — |
| D23 | Navigator stays mounted under the lock cover (pointer/semantics/tickers disabled) | Drafts survive background-lock. | Unmounting on lock |
| D24 | User-facing errors are generic; details only via `debugPrint` | Avoid leaking paths/plugin internals. | Raw exception text |
| D25 | `ITSAppUsesNonExemptEncryption = NO` | Encryption only protects user data at rest on device (exempt). Confirmed by security review. | — |
| D26 | Integration test on the simulator doubles as screenshot generator | One script gives real-device E2E coverage (Keychain + encrypted store) and repeatable App Store screenshots. It caught a real bug (fast star + stage tap lost the star). | Manual screenshots |
| D27 | Release builds strip symbols (dSYM kept) | MobSF warning; smaller binary, harder reverse engineering. | — |
| D28 | MobSF `@rpath` / malloc / insecure-API warnings accepted | They come from the Flutter engine and framework embedding and can't be removed in a Flutter app. | Native rewrite |
| D29 | Security-review sub-agent ran on Sonnet 5.5 (agent definition default), not Opus | Oversight: the owner asked for Opus throughout and the model wasn't overridden. Its findings were all verified and fixed by the main Opus session, with tests. ~0.6% of tokens. | Re-run on Opus (offered) |
| D30 | Voice capture uses **on-device** Apple speech recognition only, no server fallback | Keeps the "nothing leaves the phone" promise (spec anti-goal: no network). Trade-off: unavailable on languages/devices without on-device models — user is told plainly. | Apple server recognition; Whisper model bundled (+~75 MB) |
| D31 | `speech_to_text` 7.5.0 plugin | Thin wrapper over `SFSpeechRecognizer`, sets `requiresOnDeviceRecognition`, no networking code (verified in source). | Custom platform channel |
| D32 | Mic FAB on inbox + mic toggle in capture sheet; first sentence → title only if title empty | Fastest path from thought to saved idea, never overwrites what the user typed. | Separate voice screen |
| D33 | Spoken save command recognised **only at the end** of the transcript, from a fixed phrase list containing “idea” / “now” / “done, save” | Hands-free saving without false triggers: “save” is common inside idea descriptions (“save money”, “save it”). Fixed regex, no extra model, testable. | Wake word; any “save” word; LLM intent parsing (would need network) |
| D34 | Dictation silence timeout raised from 4 s to 30 s (max 5 min) | Owner wants the app to wait until they say “save the idea”; thinking pauses must not end the session. | Auto-restart loop (battery, harder to reason about) |
| D35 | Search: AND of words, filler dropped, light suffix stemming, includes kind/stage labels; voice search via same on-device recogniser | Spoken queries are phrased naturally (“ideas about dog walking”); exact-substring search failed them. No search index needed at personal scale. | Fuzzy/edit-distance search; full-text index |
| D36 | `image_picker` 1.2.4 (camera, library) + `file_picker` 13.3.0 (Files) | First-party / most-used Flutter pickers; library uses PHPicker (no full-library permission); neither plugin has networking or MediaPlayer code (verified in source). | Custom platform channels; `wechat_assets_picker` |
| D37 | Attachment bytes in a separate encrypted Hive **lazy** box, same key | Same encryption and file protection as ideas with no new crypto; lazy box keeps the inbox fast because bytes load only when a thumbnail or viewer asks. Verified 15 MB round-trip. | Encrypted files on disk with per-file keys; storing bytes inside the idea record |
| D38 | Photos re-encoded ≤2048 px, quality 85, `requestFullMetadata: false`; 15 MB / 20-per-idea caps | Keeps the store small and strips location EXIF; caps bound memory since attachments are held in RAM when viewed. | Keep originals |
| D39 | Files open via the iOS share sheet from a temp decrypted copy, deleted after and swept at launch | Gives Quick Look / "Open in" / Save to Files without bundling viewers; plaintext copy is short-lived. | In-app PDF/Office viewers (extra dependencies) |
| D40 | Export JSON carries attachment metadata only | Keeps export a small, readable text backup; files can be shared individually. | Zip export with files |
| D41 | Valueztech logo (white-plate variant) in Settings → About and README; name and logo excluded from the MIT licence | Credits the builder without affecting the app's look. The brand has no reversed logo for dark backgrounds, so the white plate is used as brand rules require. Forks are told how to remove it. | Logo on launch screen (adds brand to every launch, not appropriate for an open-source tool) |
