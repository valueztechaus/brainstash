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
| D13 | Bundle id `com.valueztech.brainstash` | Owner's company domain. | — |
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
