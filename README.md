# PE Health + Triage Toolkit (Meta-style)

Production-minded incident triage toolkit for **fast debugging in live systems**:
system signals + network signals + HTTP reachability + log triage → **repeatable outputs**.

## What you get
- **One-command triage**: generates `out/report.txt` + `out/summary_http.json` (+ optional log summaries)
- **Network snapshot**: routes, interfaces, DNS check, socket summary (`ss`)
- **HTTP probe**: default `timeout=2s`, `retries=1` (automation-friendly exit codes)
- **Log triage** (optional): scans last `2000` lines → top `10` offenders + CSV/JSON outputs
- **Runbook docs** for repeatable incident response

## Quick start (Linux / WSL)
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
chmod +x scripts/*.sh

# no logs
URL="https://example.com" ./scripts/triage.sh

# with logs
URL="https://example.com" LOGFILE="/var/log/nginx/access.log" ./scripts/triage.sh

