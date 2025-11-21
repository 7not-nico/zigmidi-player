#!/bin/bash

# CPU monitoring script for MIDI player
# Usage: ./monitor_cpu.sh [pid]

PID=${1:-$$}
INTERVAL=1

echo "Monitoring CPU usage for PID $PID (Press Ctrl+C to stop)"
echo "Time    CPU%   Memory"
echo "------------------------"

while true; do
    # Get CPU and memory usage
    STATS=$(ps -p $PID -o %cpu,%mem --no-headers 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Process $PID not found"
        exit 1
    fi
    
    CPU=$(echo $STATS | awk '{print $1}')
    MEM=$(echo $STATS | awk '{print $2}')
    
    printf "%-8s %5.1f%%  %5.1f%%\n" "$(date '+%H:%M:%S')" "$CPU" "$MEM"
    sleep $INTERVAL
done