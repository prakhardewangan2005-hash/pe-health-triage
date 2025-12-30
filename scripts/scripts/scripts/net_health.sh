#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-1.1.1.1}"
OUTDIR="${OUTDIR:-out}"

mkdir -p "$OUTDIR"

# Just a thin wrapper around collect_network.sh
OUTDIR="$OUTDIR" TARGET="$TARGET" bash "$(dirname "$0")/collect_network.sh"
echo "[net] output: $OUTDIR/report.txt"
