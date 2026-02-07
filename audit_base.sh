#!/usr/bin/env bash
set -euo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="/tmp/audit_${TS}.log"

have() { command -v "$1" >/dev/null 2>&1; }
sudocmd() { if have sudo; then sudo -n "$@" 2>/dev/null || sudo "$@"; else "$@"; fi; }

section() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

run() { echo; echo "+ $*"; "$@"; }
run_soft() { echo; echo "+ $*"; "$@" || true; }

export TS OUT have sudocmd section run run_soft

{
  section "META"
  run date -u
  run_soft whoami
  run_soft id
  run_soft uname -a
} | tee "$OUT"

for f in "${AUDIT_MODULES[@]}"; do
  section "MODULE: $f"
  source "$f"
done | tee -a "$OUT"

echo
echo "AUDIT COMPLETE"
echo "LOGFILE=$OUT"
