# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/valueztechaus/brainstash/security/advisories/new)
for this repository. Expect an acknowledgement within 5 business days.

## Supported versions

Only the latest release on `main` receives fixes.

## Design summary

Brainstash is offline-only. Ideas are encrypted with AES-256 on device, the key is held in the
iOS Keychain (device-only), files use iOS Data Protection *Complete*, and the store is excluded
from backups. Full controls, scan results and review findings: [security/REPORT.md](security/REPORT.md).

## Automated checks

`./tools/security_scan.sh` runs gitleaks, osv-scanner, semgrep and `flutter analyze`.
`./tools/mobsf_scan.sh <ipa>` runs MobSF static analysis on a built app. CI runs the first set
on every push and pull request.
