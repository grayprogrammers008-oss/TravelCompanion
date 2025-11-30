#!/bin/bash

# North India Hospital Import Script
# Uses OpenStreetMap Overpass API (100% FREE)
# States: Delhi, Haryana, Punjab, Uttar Pradesh, Uttarakhand, Rajasthan, Himachal Pradesh

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🏥 North India Hospital Import"
echo "================================================"
echo "States: Delhi, Haryana, Punjab, UP, Uttarakhand,"
echo "        Rajasthan, Himachal Pradesh"
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

# Import each state (bounding boxes from OpenStreetMap)
import_state "delhi" "Delhi (NCT)" "28.4,76.8,28.9,77.4"
import_state "haryana" "Haryana" "27.6,74.4,30.9,77.6"
import_state "punjab" "Punjab" "29.5,73.9,32.6,76.9"
import_state "uttar_pradesh" "Uttar Pradesh" "23.8,77.0,30.4,84.6"
import_state "uttarakhand" "Uttarakhand" "28.7,77.6,31.5,81.0"
import_state "rajasthan" "Rajasthan" "23.0,69.5,30.2,78.3"
import_state "himachal_pradesh" "Himachal Pradesh" "30.4,75.5,33.3,79.0"

echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo ""
echo "📁 Files saved to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR"/*_hospitals.json 2>/dev/null || echo "No files found"
echo ""

# Summary with jq if available
if command -v jq &> /dev/null; then
    echo "📊 Summary:"
    total_hospitals=0
    for file in "$OUTPUT_DIR"/*_hospitals.json; do
        if [ -f "$file" ]; then
            count=$(jq '.elements | length' "$file" 2>/dev/null || echo "0")
            total_hospitals=$((total_hospitals + count))
            filename=$(basename "$file")
            printf "   %-30s %s hospitals\n" "$filename" "$count"
        fi
    done
    echo "   ────────────────────────────────────────────"
    echo "   Total:                         $total_hospitals hospitals"
    echo ""
fi

echo "🎯 Next Steps:"
echo "1. Review the JSON files in $OUTPUT_DIR/"
echo "2. Ensure Supabase credentials are set in scripts/import_osm_hospitals.dart"
echo "3. Run: dart run scripts/import_osm_hospitals.dart"
echo "4. Verify import: Check Supabase dashboard"
echo ""
echo "💰 Cost: \$0 (100% FREE with OpenStreetMap!)"
echo ""
