#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

echo "== Athena Audit Framework bootstrap =="

# --- guardrails ---
[[ -d .git ]] || { echo "FATAL: run inside an existing git repo (missing .git)"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "FATAL: git not found"; exit 1; }

# --- repo context (no hardcode) ---
REPO_DIR="$(pwd)"
REPO_NAME="$(basename "$REPO_DIR")"

# Allow override; otherwise reuse existing origin if present
REMOTE_URL="${REMOTE_URL:-}"
if [[ -z "$REMOTE_URL" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    REMOTE_URL="$(git remote get-url origin)"
  else
    echo "FATAL: no origin remote. Set REMOTE_URL=git@github.com:<user>/<repo>.git"
    exit 1
  fi
fi

# --- files (idempotent) ---
echo "Writing README.md"
cat > README.md <<'MD'
# Athena Audit Framework

Framework de auditoría técnica **read-only**, reproducible y orientado a evidencias.

## Objetivo
- Auditorías reales (SRE/DevOps/AppSec)
- Evidencias verificables
- Seguro para repos públicos (sin secretos)
- Modular y extensible (profiles)

## Contrato de salida
Los scripts deben terminar con una línea:
`RESULT=<PASS|FAIL> reasons="..."`

Esto permite:
- Lectura humana (resumen claro)
- Lectura máquina (n8n / agentes / CI)

MD

echo "Writing .gitignore"
cat > .gitignore <<'GI'
*.log
out/
tmp/
*.bak
.env
.vscode/
.idea/
GI

echo "Writing LICENSE (Apache-2.0 header only; replace with full text if desired)"
cat > LICENSE <<'LIC'
Apache License Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright 2026
LIC

# --- sanity: secrets scan (exclude .git; only trackable files) ---
echo "== Secret scan (working tree, excluding .git) =="
# scan only tracked + untracked (not ignored), excluding .git, binaries suppressed
FILES="$(git ls-files -co --exclude-standard | tr '\n' ' ')"
if [[ -n "${FILES// /}" ]]; then
  if rg -n --no-messages -S --hidden --glob '!.git/*' \
    "(BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z\\-_]{35}|-----BEGIN PGP PRIVATE KEY BLOCK-----|password\\s*[:=]|passwd\\s*[:=]|secret\\s*[:=]|token\\s*[:=]|api[_-]?key\\s*[:=])" \
    $FILES; then
    echo "FATAL: potential secret detected (see matches above)"
    exit 1
  fi
fi
echo "OK: no obvious secrets found"

# --- git ops ---
git add README.md .gitignore LICENSE bootstrap_athena_audit_repo.sh
git commit -m "chore: add bootstrap script (public-safe, reusable)" || true
git branch -M main
git push -u origin main

echo "== DONE =="
git status -sb
echo "BACKUP=${BK}"
echo "REMOTE_URL=${REMOTE_URL}"
