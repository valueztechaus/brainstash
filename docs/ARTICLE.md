# From one message to an app on my iPhone in an afternoon

*By Biplab Das Choudhury, Founder & Principal Consultant, Valueztech · 28 October 2026*

At 11:39 on a Wednesday morning I typed a single message into Claude Code. I asked for an iOS app to
capture the product, service and problem ideas that come to me at odd times, so I could review them
later and pick up the ones worth building. I asked for it to be designed first, built in Flutter,
tested in the iOS simulator, secured and security-tested with standard tools, documented, ready for
the App Store, and released as a public GitHub project. I also said: do it in one shot, use your
best judgement, and record every decision.

At 12:26 the first version was running in the simulator. By 16:14 it was running on my own iPhone
with voice capture, hands-free saving, voice search and photo and file attachments. The whole thing
is open source at [github.com/valueztechaus/brainstash](https://github.com/valueztechaus/brainstash).

I want to share what actually happened, including the parts that were not automatic, because I
believe this changes what Valueztech can offer our clients.

## The timeline

All times are AEDT on 28 October 2026, taken from the session log and git history.

| Time | What happened |
|---|---|
| 11:39 | One message with the full brief |
| 11:40–12:20 | Design in Claude Design, Flutter project, encrypted storage, tests. Xcode was not installed on my Mac, so I installed it from the App Store in parallel. That download was the longest wait of the day |
| 12:26 | v1 running in the iPhone simulator: capture, search, kinds and stages, Face ID lock, AES-256 encryption, app icon |
| 12:34 | Security scans, App Store checklist, privacy policy, decision log and token report committed and pushed to GitHub |
| 12:41 | I asked for voice input. Built on-device only, so audio never leaves the phone |
| 14:41–15:03 | Getting it onto my iPhone. Most of this was Apple account housekeeping: accepting a new licence agreement, a bundle identifier that was already taken, replacing an old signing certificate, and trusting the Mac on the phone |
| 15:56–16:01 | "Wait until I say save the idea", plus search by voice. Five minutes from request to running on the phone |
| 16:05–16:14 | Attach photos from the camera or library, or documents from Files. Nine minutes, encrypted like everything else |

I typed about fifteen messages in total. Several of them were just "done" while I plugged in a cable or
clicked a button in Xcode.

## What was built

Brainstash is a small app, but it is not a demo. It has the things I would expect from a production
mobile app delivered to a client:

- **Encryption at rest** with AES-256. The key is generated on the device and kept in the iOS
  Keychain, never synced to iCloud. Ideas and attachments are excluded from backups.
- **Optional Face ID lock**, with re-authentication before export or delete-all, and a privacy cover
  in the app switcher.
- **No network at all.** No accounts, no analytics, no crash reporting. Speech recognition is forced
  on-device.
- **95 automated tests**, including tests that read the raw database file to prove nothing is stored
  in plain text, and an integration test on the simulator that also produced the App Store
  screenshots.
- **Security testing on every change** with gitleaks (secrets), osv-scanner (dependency CVEs),
  semgrep (static analysis) and MobSF (mobile app scan of the built binary). All clean, and they run
  in GitHub Actions on every push.
- **40 recorded decisions**, each with the reason and the alternative that was rejected. A design
  spec, an implementation plan, a security report and an App Store submission checklist.

## What it cost in tokens

I asked Claude Code to track token usage from the start so I could be open about it. For the whole
day, including every feature above:

| | Tokens |
|---|---|
| Output (what Claude actually wrote) | 212,651 |
| Fresh input | 478 |
| Cache writes | 451,970 |
| Cache reads | 39,224,447 |
| **Total** | **39,889,546** |

Nearly all of the total is cache reads. Every turn re-reads the conversation so far, and cached
reads are billed at a small fraction of normal input. The full breakdown and the script that
produced it are in the repository.

## What was not automatic

I don't want to oversell this. A few things still needed me:

- **Installing Xcode** and **Apple developer account steps.** Accepting Apple's updated agreement,
  choosing the signing team and plugging in the phone are things only the account owner can do. Claude
  told me exactly what to click each time, but I had to click it.
- **One confusing moment.** After the automated simulator test, the build left on the simulator was
  the test build, so taps did not work. It took one message to find and fix, and a note was added to
  the README so others don't hit it.
- **One oversight.** The independent security review ran on a smaller model than the one I asked
  for, because that reviewer agent had its own default. Its findings were checked and fixed, and the
  slip is recorded openly in the decision log.
- **Judgement still matters.** The quality came from the brief: security, testing, documentation
  and an open record of decisions were in the first message. If you don't ask for them, you are less
  likely to get them.

## What this means for our clients

In my years delivering Maximo and EAM projects, I have seen good ideas for small tools wait months
for a slot in the backlog: a field inspection app, a simple capture form for crews wearing gloves, a
prototype to test an idea with a few technicians before committing budget. The cost of trying was
too high, so most of them were never tried.

That cost has dropped sharply. Valueztech can now take a well-written brief to a working, secured,
tested and documented mobile app in hours, then iterate with the people who will use it on the same
day. We still apply the same engineering discipline we use on enterprise projects: encryption,
security scans, tests and a decision log. The difference is how quickly we get there.

If you have a tool your field teams have been asking for, or an idea you want to test with real users
before you commit a budget, I would like to hear about it.

**Biplab Das Choudhury**, Founder & Principal Consultant, Valueztech
IBM Champion 2026 · IBM Silver Partner · AWS Certified Solutions Architect
biplabchoudhury@valueztech.com · www.valueztech.com
