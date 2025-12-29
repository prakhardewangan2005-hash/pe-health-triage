#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-out}"
TIMEOUT="${TIMEOUT:-2}"
RETRIES="${RETRIES:-1}"
TAIL="${TAIL:-2000}"
TOP="${TOP:-10}"
URL="${URL:-https://example.com}"
LOGFILE="${LOGFILE:-}"

mkdir -p "$OUT_DIR"

echo "=== PE TRIAGE ===" | tee "$OUT_DIR/report.txt"
echo "out_dir=$OUT_DIR timeout=${TIMEOUT}s retries=$RETRIES tail=$TAIL top=$TOP url=$URL logfile=${LOGFILE:-<none>}" | tee -a "$OUT_DIR/report.txt"

./scripts/collect_system.sh "$OUT_DIR/report.txt"
./scripts/collect_network.sh "$OUT_DIR/report.txt"

python -m triage.http_probe "$URL" --timeout "$TIMEOUT" --retries "$RETRIES" --json "$OUT_DIR/summary_http.json" | tee -a "$OUT_DIR/report.txt"
HTTP_RC=${PIPESTATUS[0]}

LOG_RC=0
if [[ -n "${LOGFILE}" ]]; then
  python -m triage.log_triage "$LOGFILE" --tail "$TAIL" --top "$TOP" --csv "$OUT_DIR/summary_logs.csv" --json "$OUT_DIR/summary_logs.json" | tee -a "$OUT_DIR/report.txt"
  LOG_RC=${PIPESTATUS[0]}
else
  echo "log_triage: skipped (set LOGFILE=/path/to/log)" | tee -a "$OUT_DIR/report.txt"
fi

FINAL=0
if [[ "$HTTP_RC" -eq 11 ]]; then FINAL=2; fi
if [[ "$HTTP_RC" -eq 10 ]]; then FINAL=1; fi
if [[ "$LOG_RC" -eq 1 ]]; then FINAL=1; fi
if [[ "$LOG_RC" -ge 2 ]]; then FINAL=2; fi

echo "FINAL_EXIT=$FINAL" | tee -a "$OUT_DIR/report.txt"
exit "$FINAL"
