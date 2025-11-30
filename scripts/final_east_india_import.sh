#!/bin/bash

# Final attempt for remaining East India states
# Using maximum timeouts and extended wait times

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

echo "🏥 Final East India Import Attempt"
echo "================================================"
echo "Remaining states: 7"
echo "Strategy: Maximum timeout (300s), 20s wait between requests"
echo "================================================"
echo ""

import_state() {
    local state_name=$1
    local state_display=$2
    local bbox=$3
    local output_file="$OUTPUT_DIR/${state_name}_hospitals.json"

    echo "📍 $state_display..."
    echo "   Bbox: $bbox"
    echo "   Timeout: 300 seconds"

    # Maximum timeout query
    local query="[out:json][timeout:300];
    (
      node[\"amenity\"=\"hospital\"]($bbox);
      way[\"amenity\"=\"hospital\"]($bbox);
      relation[\"amenity\"=\"hospital\"]($bbox);
    );
    out center;
    out tags;"

    echo -n "   Downloading... "

    curl -X POST "$OVERPASS_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "data=$query" \
      -o "$output_file" \
      --max-time 350 \
      --connect-timeout 60 \
      --silent --show-error 2>&1 | head -1

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        # Check if it's valid JSON or an error
        if head -1 "$output_file" | grep -q "xml version"; then
            echo "❌ API Error (timeout/busy)"
            return 1
        else
            local file_size=$(du -h "$output_file" | cut -f1)
            local count=0
            if command -v jq &> /dev/null; then
                count=$(jq '.elements | length' "$output_file" 2>/dev/null || echo "0")
            fi
            echo "✅ $file_size ($count hospitals)"
        fi
    else
        echo "❌ Download failed"
        return 1
    fi

    echo "   Waiting 20 seconds before next request..."
    echo ""
    sleep 20
}

# Import each state with maximum patience
import_state "jharkhand" "Jharkhand" "21.9,83.3,25.3,87.9"
import_state "odisha" "Odisha" "17.8,81.3,22.6,87.5"
import_state "sikkim" "Sikkim" "27.0,88.0,28.1,88.9"
import_state "assam" "Assam" "24.1,89.7,27.9,96.0"
import_state "arunachal_pradesh" "Arunachal Pradesh" "26.6,91.6,29.5,97.4"
import_state "nagaland" "Nagaland" "25.2,93.3,27.0,95.2"
import_state "manipur" "Manipur" "23.8,93.0,25.7,94.8"

echo "================================================"
echo "✅ Download attempt complete!"
echo "================================================"
echo ""
echo "Files downloaded to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR"/{jharkhand,odisha,sikkim,assam,arunachal_pradesh,nagaland,manipur}_hospitals.json 2>/dev/null
echo ""
