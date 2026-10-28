#!/usr/bin/env bash
# Run all automated security checks. Reports land in security/reports/.
# Requires: gitleaks, osv-scanner, semgrep (brew install gitleaks osv-scanner semgrep)
# Optional: MobSF via Docker for the built app (see tools/mobsf_scan.sh).
set -uo pipefail
cd "$(dirname "$0")/.."
OUT=security/reports
mkdir -p "$OUT"
status=0

echo "== gitleaks: secrets in working tree + git history =="
gitleaks dir . --redact --no-banner --report-format json --report-path "$OUT/gitleaks.json" || status=1
if git rev-parse --git-dir >/dev/null 2>&1 && git rev-parse HEAD >/dev/null 2>&1; then
  gitleaks git . --redact --no-banner --report-format json --report-path "$OUT/gitleaks-history.json" || status=1
fi

echo "== osv-scanner: known CVEs in pub dependencies =="
osv-scanner scan source --lockfile pubspec.lock --format markdown > "$OUT/osv.md" || status=1
sed -i.bak "s#$PWD/##" "$OUT/osv.md" && rm -f "$OUT/osv.md.bak"
cat "$OUT/osv.md"

echo "== semgrep: SAST (Dart, Swift, secrets, OWASP) =="
semgrep scan --metrics=off --quiet --error \
  --config p/secrets --config p/owasp-top-ten --config p/swift --config r/dart \
  --exclude build --exclude .dart_tool --exclude ios/Pods \
  --json --output "$OUT/semgrep.json" . || status=1
python3 -c "import json;d=json.load(open('$OUT/semgrep.json'));print(f\"semgrep findings: {len(d['results'])}, errors: {len(d['errors'])}\");[print(' -',r['check_id'],r['path'],r['start']['line']) for r in d['results']]"

echo "== flutter analyze (strict) =="
flutter analyze || status=1

exit $status
