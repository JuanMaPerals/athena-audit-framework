#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ===== context =====
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUT:-/tmp/audit_${TS}.log}"

# ===== helpers =====
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

# ===== RESULT contract =====
if [[ -f "./lib/result.sh" ]]; then
  # shellcheck disable=SC1091
  source "./lib/result.sh"
else
  RESULT="PASS"; REASONS=()
  fail(){ RESULT="FAIL"; REASONS+=("$*"); }
  result_line(){ if ((${#REASONS[@]})); then echo "RESULT=${RESULT} reasons=\"${REASONS[*]}\""; else echo "RESULT=${RESULT}"; fi; }
fi

# ===== module selection =====
MODULES=()
if (($# > 0)); then
  MODULES=("$@")
elif [[ "${AUDIT_MODULES+x}" == "x" ]] && ((${#AUDIT_MODULES[@]})); then
  MODULES=("${AUDIT_MODULES[@]}")
else
  echo "FATAL: no modules provided."
  echo "Usage: $0 <module1.sh> [module2.sh ...]"
  fail "no modules"
  result_line
  echo "LOGFILE=${OUT}"
  exit 2
fi

# ===== logging (full transcript) =====
mkdir -p "$(dirname "$OUT")" 2>/dev/null || true
exec > >(tee "$OUT") 2>&1

section "META"
run date -u
run_soft whoami
run_soft id
run_soft pwd
run_soft uname -a

# ===== run modules (non-fatal sourcing) =====
for m in "${MODULES[@]}"; do
  section "MODULE: ${m}"
  if [[ ! -f "$m" ]]; then
    echo "MISSING_MODULE=${m}"
    fail "missing module: ${m}"
    continue
  fi

  set +e
  # shellcheck disable=SC1090
  source "$m"
  rc=$?
  set -e
  if ((rc != 0)); then
    echo "MODULE_EXIT_CODE=${rc} module=${m}"
    fail "module failed: ${m} (exit ${rc})"
  fi
done

section "SUMMARY"
result_line
echo "LOGFILE=${OUT}"
