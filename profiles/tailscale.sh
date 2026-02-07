if ! have tailscale; then
  echo "tailscale: NOT FOUND"
  return
fi

run_soft sudocmd tailscale status
run_soft sudocmd tailscale serve status
run_soft sudocmd ss -ltnp | egrep ':(80|443|3000)\s' || true
