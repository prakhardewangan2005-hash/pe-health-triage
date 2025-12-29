#!/usr/bin/env bash
set -euo pipefail
REPORT="${1:-out/report.txt}"

{
  echo
  echo "=== NETWORK ==="
  echo "--- interfaces ---"
  ip -br a 2>/dev/null || true

  echo "--- routes ---"
  ip route 2>/dev/null | sed -n '1,30p' || true

  echo "--- dns quick ---"
  getent hosts google.com 2>/dev/null && echo "dns_ok=true" || echo "dns_ok=false"

  echo "--- sockets (ss summary) ---"
  if command -v ss >/dev/null 2>&1; then
    echo "[listeners]"
    ss -lntup 2>/dev/null | sed -n '1,30p' || true

    echo "[top established by remote]"
    ss -ntp 2>/dev/null | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | sed -n '1,12p' || true
  else
    echo "ss_missing=true"
  fi
} >> "$REPORT"
