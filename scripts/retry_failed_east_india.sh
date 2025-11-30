#!/bin/bash

# Retry failed East India downloads with extended timeout

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

echo "🔄 Retrying Failed East India Downloads"
echo "================================================"
echo ""

import_state() {
    local state_name=$1
    local state_display=$2
    local bbox=$3
    local output_file="$OUTPUT_DIR/${state_name}_hospitals.json"

    echo "📍 Importing $state_display..."
    echo "   Bounding Box: $bbox"

    # Overpass query with extended timeout
    local query="[out:json][timeout:180];
    (
      node[\"amenity\"=\"hospital\"]($bbox);
      way[\"amenity\"=\"hospital\"]($bbox);
      relation[\"amenity\"=\"hospital\"]($bbox);
    );
    out center;
    out tags;"

    echo "   Requesting data (extended timeout: 180s)..."
    curl -X POST "$OVERPASS_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "data=$query" \
      -o "$output_file" \
      --max-time 200 \
      --progress-bar 2>&1 | grep -oP '\d+%|\d+\.\d+[KMG]' | tail -1

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        echo "   ✅ Success: Data saved ($file_size)"
    else
        echo "   ❌ Failed to download"
        return 1
    fi

    echo ""
    echo "   ⏳ Waiting 10 seconds before next request..."
    sleep 10
    echo ""
}

# Retry failed states with longer timeout and wait times
import_state "west_bengal" "West Bengal" "21.5,85.8,27.2,89.9"
import_state "bihar" "Bihar" "24.3,83.3,27.5,88.3"
import_state "jharkhand" "Jharkhand" "21.9,83.3,25.3,87.9"
import_state "odisha" "Odisha" "17.8,81.3,22.6,87.5"
import_state "sikkim" "Sikkim" "27.0,88.0,28.1,88.9"
import_state "nagaland" "Nagaland" "25.2,93.3,27.0,95.2"

echo "================================================"
echo "✅ Retry Complete!"
echo "================================================"
