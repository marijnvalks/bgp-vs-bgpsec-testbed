#!/bin/bash

#Starts docker stats collecting on all quagga routers including srx_server if present.

OUTFILE="$1"
INTERVAL=0.2  # 200 ms

echo "timestamp_ns,container,cpu_perc,mem_usage" > "$OUTFILE"

while true; do
  ts=$(date +%s%N)
  docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}}' \
    | grep -iE '^quagga_[0-9]+|^quaggasrx_[0-9]+|srx_server' \
    | while IFS= read -r line; do
        echo "$ts,$line" >> "$OUTFILE"
      done
  sleep $INTERVAL
done
