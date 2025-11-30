#!/bin/bash

# Retry specific failed states one by one with long wait times

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

echo "🔄 Retrying Specific Failed States"
echo "================================================"
echo ""

import_state() {
    local state_name=$1
    local state_display=$2
    local bbox=$3
    local output_file="$OUTPUT_DIR/${state_name}_hospitals.json"

    echo "📍 $state_display..."

    local query="[out:json][timeout:180];
    (
      node[\"amenity\"=\"hospital\"]($bbox);
      way[\"amenity\"=\"hospital\"]($bbox);
      relation[\"amenity\"=\"hospital\"]($bbox);
    );
    out center;
    out tags;"

    curl -X POST "$OVERPASS_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "data=$query" \
      -o "$output_file" \
      --max-time 200 \
      --silent --show-error

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        echo "   ✅ $file_size"
    else
        echo "   ❌ Failed"
    fi

    echo "   ⏳ Waiting 15 seconds..."
    sleep 15
}

# Retry only the failed states
import_state "bihar" "Bihar" "24.3,83.3,27.5,88.3"
import_state "jharkhand" "Jharkhand" "21.9,83.3,25.3,87.9"
import_state "odisha" "Odisha" "17.8,81.3,22.6,87.5"
import_state "sikkim" "Sikkim" "27.0,88.0,28.1,88.9"
import_state "assam" "Assam" "24.1,89.7,27.9,96.0"
import_state "arunachal_pradesh" "Arunachal Pradesh" "26.6,91.6,29.5,97.4"
import_state "nagaland" "Nagaland" "25.2,93.3,27.0,95.2"
import_state "manipur" "Manipur" "23.8,93.0,25.7,94.8"

echo ""
echo "✅ Done!"
