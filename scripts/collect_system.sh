#!/usr/bin/env bash
set -euo pipefail
REPORT="${1:-out/report.txt}"

{
  echo
  echo "=== SYSTEM ==="
  date || true
  uname -a || true

  echo "--- uptime ---"
  uptime || true

  echo "--- cpu/mem ---"
  command -v free >/dev/null 2>&1 && free -h || true
  command -v lscpu >/dev/null 2>&1 && lscpu | sed -n '1,20p' || true

  echo "--- disk ---"
  df -hT | sed -n '1,12p' || true

  echo "--- top (snapshot) ---"
  ps aux --sort=-%mem | sed -n '1,15p' || true
} >> "$REPORT"
