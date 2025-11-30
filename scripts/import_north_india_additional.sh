#!/bin/bash

# Additional North India Hospital Import Script
# Union Territories: Jammu & Kashmir, Chandigarh, Ladakh

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🏥 Additional North India Hospital Import"
echo "================================================"
echo "Regions: Jammu & Kashmir, Chandigarh, Ladakh"
echo "API: OpenStreetMap Overpass (100% FREE)"
echo "Output: $OUTPUT_DIR/"
echo "================================================"
echo ""

# Function to import hospitals from a region
import_region() {
    local region_name=$1
    local region_display=$2
    local bbox=$3
    local output_file="$OUTPUT_DIR/${region_name}_hospitals.json"

    echo "📍 Importing $region_display..."
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

# Import each region (bounding boxes from OpenStreetMap)
import_region "jammu_kashmir" "Jammu & Kashmir" "32.3,73.5,37.1,80.3"
import_region "chandigarh" "Chandigarh (UT)" "30.6,76.7,30.8,76.9"
import_region "ladakh" "Ladakh (UT)" "32.2,75.2,36.0,79.9"

echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo ""
echo "📁 Files saved to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR"/*_hospitals.json 2>/dev/null | tail -3
echo ""

# Summary with jq if available
if command -v jq &> /dev/null; then
    echo "📊 Summary (Additional Regions):"
    total_hospitals=0
    for file in "$OUTPUT_DIR"/jammu_kashmir_hospitals.json "$OUTPUT_DIR"/chandigarh_hospitals.json "$OUTPUT_DIR"/ladakh_hospitals.json; do
        if [ -f "$file" ]; then
            count=$(jq '.elements | length' "$file" 2>/dev/null || echo "0")
            total_hospitals=$((total_hospitals + count))
            filename=$(basename "$file")
            printf "   %-30s %s hospitals\n" "$filename" "$count"
        fi
    done
    echo "   ────────────────────────────────────────────"
    echo "   Additional Total:              $total_hospitals hospitals"
    echo ""
fi

echo "🎯 Next Steps:"
echo "1. Review the JSON files in $OUTPUT_DIR/"
echo "2. Update import script to include these regions"
echo "3. Run: dart run scripts/import_osm_hospitals.dart"
echo ""
echo "💰 Cost: \$0 (100% FREE with OpenStreetMap!)"
echo ""
