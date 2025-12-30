#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${OUT_DIR:-out}"
TARGET="${TARGET:-1.1.1.1}"

mkdir -p "$OUT_DIR"

{
  echo "=== date ==="
  date -Is || true
  echo

  echo "=== hostname ==="
  hostname || true
  echo

  echo "=== ip addr ==="
  command -v ip >/dev/null 2>&1 && ip addr || true
  echo

  echo "=== ip route ==="
  command -v ip >/dev/null 2>&1 && ip route || true
  echo

  echo "=== ip neigh ==="
  command -v ip >/dev/null 2>&1 && ip neigh || true
  echo

  echo "=== ss summary ==="
  command -v ss >/dev/null 2>&1 && ss -s || true
  echo

  echo "=== ping ${TARGET} ==="
  command -v ping >/dev/null 2>&1 && ping -c 5 -W 2 "$TARGET" || true
  echo

  echo "=== resolv.conf ==="
  test -f /etc/resolv.conf && cat /etc/resolv.conf || true
  echo

  echo "=== DNS check (dig/nslookup) ==="
  if command -v dig >/dev/null 2>&1; then
    dig +time=2 +tries=1 example.com | head -n 30 || true
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup example.com || true
  else
    echo "dig/nslookup not found"
  fi
} > "${OUT_DIR}/network_snapshot.txt"
