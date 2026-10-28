#!/usr/bin/env bash
# Static analysis of the built iOS app with MobSF (Docker).
# Usage: tools/mobsf_scan.sh path/to/App.ipa   (or a zipped Runner.app)
set -euo pipefail
cd "$(dirname "$0")/.."
FILE=${1:?usage: mobsf_scan.sh <ipa>}
OUT=security/reports
mkdir -p "$OUT"
KEY=$(openssl rand -hex 32)
NAME=brainstash-mobsf
PORT=${MOBSF_PORT:-8765}
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p 127.0.0.1:$PORT:8000 -e MOBSF_API_KEY="$KEY" \
  opensecurity/mobile-security-framework-mobsf:latest >/dev/null
trap 'docker rm -f "$NAME" >/dev/null 2>&1' EXIT
until curl -sf http://127.0.0.1:$PORT/ >/dev/null; do sleep 3; done

HASH=$(curl -sf -H "Authorization: $KEY" -F "file=@$FILE" http://127.0.0.1:$PORT/api/v1/upload | python3 -c 'import json,sys;print(json.load(sys.stdin)["hash"])')
curl -sf -H "Authorization: $KEY" -d "hash=$HASH" http://127.0.0.1:$PORT/api/v1/scan > "$OUT/mobsf.json"
curl -sf -H "Authorization: $KEY" -d "hash=$HASH" http://127.0.0.1:$PORT/api/v1/scorecard > "$OUT/mobsf-scorecard.json"
python3 - "$OUT" <<'EOF'
import json, sys, pathlib
out = pathlib.Path(sys.argv[1])
sc = json.loads((out / "mobsf-scorecard.json").read_text())
lines = ["# MobSF scorecard", "", f"- Security score: **{sc.get('security_score')}/100**",
         f"- Trackers: {sc.get('trackers', {}).get('detected_trackers', 0) if isinstance(sc.get('trackers'), dict) else sc.get('trackers')}", ""]
for sev in ("high", "warning", "info", "secure", "hotspot"):
    items = sc.get(sev) or []
    lines.append(f"## {sev.title()} ({len(items)})")
    lines += [f"- {i.get('title')}" for i in items] + [""]
(out / "mobsf.md").write_text("\n".join(lines))
print("\n".join(lines))
EOF
