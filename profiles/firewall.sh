if have ufw; then
  run_soft sudocmd ufw status verbose
else
  echo "ufw: NOT FOUND"
fi
