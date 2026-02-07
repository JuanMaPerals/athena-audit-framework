if ! have docker; then
  echo "docker: NOT FOUND"
  return
fi

run_soft docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
run_soft docker network ls
run_soft docker volume ls
