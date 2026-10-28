# Contributing

Thanks for helping! Keep Brainstash small, private and offline.

1. Fork, then branch: `feature/short-description` or `fix/short-description`.
2. `flutter pub get && flutter test && flutter analyze` must pass.
3. `./tools/security_scan.sh` must pass.
4. Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`).
5. Open a PR describing the change and how you tested it.

**Ground rules**

- No network calls, analytics, crash reporters or ad SDKs. PRs adding them will be declined.
- New dependencies need a reason in the PR and an exact version pin.
- Data stays encrypted at rest. Don't add plaintext caches.
- Add a test for every behaviour change (happy path + one failure case).
