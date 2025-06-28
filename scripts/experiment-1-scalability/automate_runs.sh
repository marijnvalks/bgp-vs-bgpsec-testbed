#!/bin/bash

# Explanation: Start test experiments for N amount of iterations, using BGP or BGPsec based on input and the amount of 'runs'. 
# Based on the topology you run, change the place of the docker-compose file in line 30, 31 and 33. For BGPsec 'restart' did not always complete reset containers, therefore down/up is used.

set -e

# Usage: ./automate_runs.sh <bgp|bgpsec> <number_of_runs>
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <bgp|bgpsec> <number_of_runs>"
  exit 1
fi

MODE="$1"
NUM_RUNS="$2"

if [[ "$MODE" != "bgp" && "$MODE" != "bgpsec" ]]; then
  echo "Invalid mode: $MODE. Must be 'bgp' or 'bgpsec'."
  exit 1
fi

for i in $(seq 1 "$NUM_RUNS"); do
  RUN_NAME="run${i}"
  echo "==========================================="
  echo ">> Starting $RUN_NAME of $NUM_RUNS in $MODE mode"
  echo "==========================================="

  echo "[STEP] Restarting Docker containers..."
  if [[ "$MODE" == "bgpsec" ]]; then
    docker compose -f ../../topologies/twenty_routers/quaggasrx-bgpsec/docker-compose.yml down
    docker compose -f ../../topologies/twenty_routers/quaggasrx-bgpsec/docker-compose.yml up -d
  else
    docker compose -f ../../topologies/ten_routers/kathara-quagga/docker-compose.yml restart
  fi

  echo "[STEP] Waiting for containers to stabilize..."
  sleep 8

  echo "[STEP] Executing $MODE test for $RUN_NAME..."
  ./run_full_test.sh "$MODE" "$RUN_NAME"

  echo "[✓] $RUN_NAME completed"
  echo ""
done

echo "==========================================="
echo "[✓] All $NUM_RUNS runs completed for $MODE."
echo "Check experiments_results folders for output."
