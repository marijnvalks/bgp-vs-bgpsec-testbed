#!/bin/bash

#This script starts the start_docker_stats_logger.sh bash script on the host machine and start the monitor_prefix_arrival.sh script inside the router containers.
#This script is called by the automate_runs.sh script.

set -e

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 [bgp|bgpsec] [run_name]"
  exit 1
fi

MODE="$1"
RUN_NAME="$2"

# Sanitize RUN_NAME
if [[ ! "$RUN_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "[ERROR] Invalid run name: $RUN_NAME"
  exit 1
fi

DATESTAMP=$(date +%m%d)
SYNC_ANCHOR_FILE="sync_anchor_ns.txt"
spinner="/|\\-/"

# Determine settings based on mode
if [[ "$MODE" == "bgp" ]]; then
  CONTAINER_PREFIX="quagga_"
  INJECT_CONTAINER="exabgp"
  INJECT_COMMAND="exabgp /opt/scripts/exabgp.conf"
elif [[ "$MODE" == "bgpsec" ]]; then
  CONTAINER_PREFIX="quaggasrx_"
  INJECT_CONTAINER="bgpsec_io"
  INJECT_COMMAND="bgpsecio -f /opt/scripts/bgpsecio.conf"
else
  echo "Invalid mode: $MODE. Choose 'bgp' or 'bgpsec'."
  exit 1
fi

EXPERIMENTS_DIR="./experiments_results"
DOCKERSTATS_DIR="${EXPERIMENTS_DIR}/dockerstats"
mkdir -p "$DOCKERSTATS_DIR"

STATS_LOG="${DOCKERSTATS_DIR}/${DATESTAMP}_${RUN_NAME}.csv"

# === Kill any lingering logger processes ===
echo "[INFO] Killing any previous docker stats logger instances..."
pkill -f start_docker_stats_logger.sh || true

# === Verify container result folders ===
CONTAINERS=$(docker ps --format '{{.Names}}' | grep "^$CONTAINER_PREFIX")

if [[ -z "$CONTAINERS" ]]; then
  echo "[ERROR] No containers found with prefix $CONTAINER_PREFIX"
  exit 1
fi

for c in $CONTAINERS; do
  CONTAINER_RESULTS_PATH="${EXPERIMENTS_DIR}/${c}"
  if [[ ! -d "$CONTAINER_RESULTS_PATH" ]]; then
    echo "[WARN] Output directory missing for $c. Creating: $CONTAINER_RESULTS_PATH"
    mkdir -p "$CONTAINER_RESULTS_PATH"
  fi
done

echo "[INFO] Starting docker resource logger for $CONTAINER_PREFIX routers..."
echo "[DEBUG] Docker stats will be written to: $STATS_LOG"
./start_docker_stats_logger.sh "$STATS_LOG" &
STATS_PID=$!

echo "[INFO] Capturing 15s of baseline resource usage..."
sleep 15

for c in $CONTAINERS; do
  echo "[INFO] Launching monitor in $c"
  docker exec "$c" find /opt/experiment_output -name 'monitor_complete_*.log' -delete
  docker exec "$c" chmod +x /opt/scripts/monitor_prefix_arrival.sh
  docker exec -d "$c" bash /opt/scripts/monitor_prefix_arrival.sh "$RUN_NAME" "$MODE" 
done

echo "[INFO] Injecting prefixes from $INJECT_CONTAINER..."
docker exec -d "$INJECT_CONTAINER" $INJECT_COMMAND

spin() {
  i=$(( (i + 1) % 4 ))
  echo -ne "\r[WAIT] $1 ${spinner:$i:1}"
}

for c in $CONTAINERS; do
  echo ""
  echo "[INFO] Waiting for $c to finish..."
  while true; do
    if docker exec "$c" sh -c "ls /opt/experiment_output/monitor_complete_*.log >/dev/null 2>&1"; then
      echo -e "\r[✓] $c completed."
      break
    fi
    spin "$c"
    sleep 0.2
  done
done

echo "[INFO] Cleaning up $INJECT_CONTAINER..."
docker exec "$INJECT_CONTAINER" pkill -f "$(echo $INJECT_COMMAND | awk '{print $1}')" 2>/dev/null || echo "[INFO] $INJECT_CONTAINER already stopped."

echo "[INFO] Capturing 15s of post-test resource usage..."
sleep 15

echo "[INFO] Stopping docker resource logger..."
kill "$STATS_PID"
wait "$STATS_PID" 2>/dev/null || true

echo ""
echo "[✓] All monitoring completed successfully."
echo "[✓] Results written to:"
for c in $CONTAINERS; do
  echo "    - ${EXPERIMENTS_DIR}/${c}/rib_convergence_${DATESTAMP}_${RUN_NAME}.csv"
done
echo "    - ${STATS_LOG}"
