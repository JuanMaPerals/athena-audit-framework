#!/usr/bin/env bash
set -euo pipefail

export AUDIT_MODULES=(
  "./profiles/system.sh"
  "./profiles/firewall.sh"
  "./profiles/docker.sh"
  "./profiles/tailscale.sh"
)

bash ./audit_base.sh
