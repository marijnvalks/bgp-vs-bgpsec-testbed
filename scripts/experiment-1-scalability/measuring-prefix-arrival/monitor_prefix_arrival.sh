#!/bin/bash

#This script is launched inside the router container itself and creates a traffic dump for the router interface. 
#In parralel it checks the number of prefixes in the BGP table and checks if that number correlates with the number of prefixes in the prefixes.txt file.

# === Input Validation ===
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <run_name> <bgp|bgpsec>"
  exit 1
fi

RUN_NAME="$1"
MODE="$2"
RUN_NAME="$1"

# === Configuration ===
DATESTAMP=$(date +"%m%d")
PREFIX_LIST_FILE="/opt/scripts/prefixes.txt"
RIB_LOG_FILE="/opt/experiment_output/rib_convergence_${DATESTAMP}_${RUN_NAME}.csv"
PCAP_FILE="/opt/experiment_output/bgp_updates_${DATESTAMP}_${RUN_NAME}.pcap"
INTERFACE="eth0"
INTERVAL=0.01  # seconds
CONTAINER_NAME=$(hostname)
DONE_MARKER="/opt/experiment_output/monitor_complete_${CONTAINER_NAME}_${RUN_NAME}.log"
SYNC_MARKER="/opt/experiment_output/sync_marker_${CONTAINER_NAME}_${RUN_NAME}.log"

echo "[INFO] Starting RIB convergence monitor in container: $CONTAINER_NAME"
echo "[INFO] Output files will include run name: $RUN_NAME"

# === Validation ===
if [[ ! -f "$PREFIX_LIST_FILE" ]]; then
  echo "[ERROR] Prefix list not found: $PREFIX_LIST_FILE"
  exit 1
fi

mapfile -t PREFIXES < "$PREFIX_LIST_FILE"
TOTAL=${#PREFIXES[@]}
echo "[INFO] Expecting $TOTAL total prefixes to converge."



# === Clock Sync Marker ===
SYNC_TS=$(date +%s%N)
echo "$SYNC_TS" > "$SYNC_MARKER"
echo "[INFO] Clock sync marker logged at: $SYNC_TS ns (container-local time)"
echo "[INFO] Sync marker written to: $SYNC_MARKER"


# === Start tcpdump ===
IP_ADDR=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
tcpdump -i "$INTERFACE" tcp port 179 and host "$IP_ADDR" -w "$PCAP_FILE" >/dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 0.5

if ! kill -0 "$TCPDUMP_PID" 2>/dev/null; then
  echo "[ERROR] tcpdump failed to start"
  exit 1
fi

# === Monitor RIB for convergence ===
START_TS=0
END_TS=0

echo "[INFO] Waiting for prefix convergence..."

while true; do
  current_ts=$(date +%s%N)
  output=$(vtysh -c "show ip bgp" 2>/dev/null)
  if [[ "$MODE" == "bgpsec" ]]; then
    # Match line like: Total number of prefixes 1000
    prefixes_seen=$(echo "$output" | grep -iE 'total number of prefixes' | grep -Eo '[0-9]+' | tail -1)

  else
    # Match line like: Displayed 100 out of 100
    prefixes_seen=$(echo "$output" | grep -Eo '[Dd]isplayed[[:space:]]+[0-9]+[[:space:]]+out of[[:space:]]+[0-9]+' | grep -Eo '[0-9]+' | tail -1)
  fi

  prefixes_seen=${prefixes_seen:-0}



  if [[ "$prefixes_seen" -eq 0 ]]; then
    START_TS=$current_ts
  elif [[ "$prefixes_seen" -ge $TOTAL ]]; then
    END_TS=$current_ts
    echo "[✓] RIB converged with $prefixes_seen prefixes at $END_TS"
    break
  fi

  sleep "$INTERVAL"
done

# === Output Results ===
echo "start_time_ns,end_time_ns,total_prefixes" > "$RIB_LOG_FILE"
echo "$START_TS,$END_TS,$TOTAL" >> "$RIB_LOG_FILE"
echo "[INFO] Timestamps written to: $RIB_LOG_FILE"

# === Cleanup ===
sleep 2
kill "$TCPDUMP_PID"
wait "$TCPDUMP_PID" 2>/dev/null
echo "done at $(date +%s%N)" > "$DONE_MARKER"
echo "[INFO] Monitor complete in container: $CONTAINER_NAME"
