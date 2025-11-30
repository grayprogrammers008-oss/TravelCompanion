#!/bin/bash

# East India Hospital Import Script
# Uses OpenStreetMap Overpass API (100% FREE)
# States: West Bengal, Bihar, Jharkhand, Odisha, Sikkim
# Northeast: Assam, Arunachal Pradesh, Nagaland, Manipur, Mizoram, Tripura, Meghalaya

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🏥 East India Hospital Import"
echo "================================================"
echo "States: West Bengal, Bihar, Jharkhand, Odisha,"
echo "        Sikkim, Assam, Arunachal Pradesh,"
echo "        Nagaland, Manipur, Mizoram, Tripura, Meghalaya"
echo "API: OpenStreetMap Overpass (100% FREE)"
echo "Output: $OUTPUT_DIR/"
echo "================================================"
echo ""

# Function to import hospitals from a state
import_state() {
    local state_name=$1
    local state_display=$2
    local bbox=$3
    local output_file="$OUTPUT_DIR/${state_name}_hospitals.json"

    echo "📍 Importing $state_display..."
    echo "   Bounding Box: $bbox"

    # Overpass query
    local query="[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"]($bbox);
      way[\"amenity\"=\"hospital\"]($bbox);
      relation[\"amenity\"=\"hospital\"]($bbox);
    );
    out center;
    out tags;"

    # Make API request
    echo "   Requesting data from Overpass API..."
    curl -X POST "$OVERPASS_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "data=$query" \
      -o "$output_file" \
      --progress-bar 2>&1 | grep -oP '\d+%|\d+\.\d+[KMG]' | tail -1

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        # Check if jq is available for counting
        if command -v jq &> /dev/null; then
            local count=$(jq '.elements | length' "$output_file" 2>/dev/null || echo "unknown")
            local file_size=$(du -h "$output_file" | cut -f1)
            echo "   ✅ Success: $count hospitals ($file_size)"
        else
            local file_size=$(du -h "$output_file" | cut -f1)
            echo "   ✅ Success: Data saved ($file_size)"
        fi
    else
        echo "   ❌ Failed to download data"
        return 1
    fi

    echo ""

    # Be nice to the API - wait between requests
    echo "   ⏳ Waiting 5 seconds before next request..."
    sleep 5
    echo ""
}

# East India - Major States
import_state "west_bengal" "West Bengal" "21.5,85.8,27.2,89.9"
import_state "bihar" "Bihar" "24.3,83.3,27.5,88.3"
import_state "jharkhand" "Jharkhand" "21.9,83.3,25.3,87.9"
import_state "odisha" "Odisha" "17.8,81.3,22.6,87.5"
import_state "sikkim" "Sikkim" "27.0,88.0,28.1,88.9"

# Northeast - Seven Sister States
import_state "assam" "Assam" "24.1,89.7,27.9,96.0"
import_state "arunachal_pradesh" "Arunachal Pradesh" "26.6,91.6,29.5,97.4"
import_state "nagaland" "Nagaland" "25.2,93.3,27.0,95.2"
import_state "manipur" "Manipur" "23.8,93.0,25.7,94.8"
import_state "mizoram" "Mizoram" "21.9,92.2,24.5,93.5"
import_state "tripura" "Tripura" "22.9,91.0,24.5,92.5"
import_state "meghalaya" "Meghalaya" "25.0,89.8,26.1,92.8"

echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo ""
echo "📁 Files saved to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR"/*_hospitals.json 2>/dev/null | tail -12
echo ""

# Summary with jq if available
if command -v jq &> /dev/null; then
    echo "📊 Summary:"
    total_hospitals=0
    for file in "$OUTPUT_DIR"/west_bengal_hospitals.json \
                "$OUTPUT_DIR"/bihar_hospitals.json \
                "$OUTPUT_DIR"/jharkhand_hospitals.json \
                "$OUTPUT_DIR"/odisha_hospitals.json \
                "$OUTPUT_DIR"/sikkim_hospitals.json \
                "$OUTPUT_DIR"/assam_hospitals.json \
                "$OUTPUT_DIR"/arunachal_pradesh_hospitals.json \
                "$OUTPUT_DIR"/nagaland_hospitals.json \
                "$OUTPUT_DIR"/manipur_hospitals.json \
                "$OUTPUT_DIR"/mizoram_hospitals.json \
                "$OUTPUT_DIR"/tripura_hospitals.json \
                "$OUTPUT_DIR"/meghalaya_hospitals.json; do
        if [ -f "$file" ]; then
            count=$(jq '.elements | length' "$file" 2>/dev/null || echo "0")
            total_hospitals=$((total_hospitals + count))
            filename=$(basename "$file")
            printf "   %-35s %s hospitals\n" "$filename" "$count"
        fi
    done
    echo "   ────────────────────────────────────────────"
    echo "   Total:                              $total_hospitals hospitals"
    echo ""
fi

echo "🎯 Next Steps:"
echo "1. Review the JSON files in $OUTPUT_DIR/"
echo "2. Update import script to include East India states"
echo "3. Run: dart run scripts/import_osm_hospitals.dart"
echo "4. Verify import in Supabase dashboard"
echo ""
echo "💰 Cost: \$0 (100% FREE with OpenStreetMap!)"
echo ""
