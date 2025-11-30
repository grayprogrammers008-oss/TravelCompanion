#!/bin/bash

# West India Hospital Import Script
# Uses OpenStreetMap Overpass API (100% FREE)
# States: Maharashtra, Gujarat, Goa, Madhya Pradesh, Chhattisgarh
# UTs: Dadra and Nagar Haveli and Daman and Diu

OVERPASS_URL="https://overpass-api.de/api/interpreter"
OUTPUT_DIR="hospital_data"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🏥 West India Hospital Import"
echo "================================================"
echo "States: Maharashtra, Gujarat, Goa,"
echo "        Madhya Pradesh, Chhattisgarh"
echo "UTs: Dadra & Nagar Haveli, Daman & Diu"
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

    # Overpass query with extended timeout
    local query="[out:json][timeout:300];
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
      --max-time 350 \
      --silent --show-error

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        # Check if it's valid JSON or an error
        if head -1 "$output_file" | grep -q "xml version"; then
            echo "   ❌ API Error (timeout/busy)"
            return 1
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
    echo "   ⏳ Waiting 20 seconds before next request..."
    sleep 20
    echo ""
}

# Import each state (bounding boxes from OpenStreetMap)
import_state "maharashtra" "Maharashtra" "15.6,72.6,22.0,80.9"
import_state "gujarat" "Gujarat" "20.1,68.2,24.7,74.5"
import_state "goa" "Goa" "14.9,73.7,15.8,74.3"
import_state "madhya_pradesh" "Madhya Pradesh" "21.1,74.0,26.9,82.8"
import_state "chhattisgarh" "Chhattisgarh" "17.8,80.0,24.1,84.4"
import_state "dnh_dd" "Dadra & Nagar Haveli and Daman & Diu" "20.0,72.6,20.7,73.2"

echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo ""
echo "📁 Files saved to: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR"/{maharashtra,gujarat,goa,madhya_pradesh,chhattisgarh,dnh_dd}_hospitals.json 2>/dev/null
echo ""

# Summary with jq if available
if command -v jq &> /dev/null; then
    echo "📊 Summary:"
    total_hospitals=0
    for file in "$OUTPUT_DIR"/maharashtra_hospitals.json \
                "$OUTPUT_DIR"/gujarat_hospitals.json \
                "$OUTPUT_DIR"/goa_hospitals.json \
                "$OUTPUT_DIR"/madhya_pradesh_hospitals.json \
                "$OUTPUT_DIR"/chhattisgarh_hospitals.json \
                "$OUTPUT_DIR"/dnh_dd_hospitals.json; do
        if [ -f "$file" ]; then
            count=$(jq '.elements | length' "$file" 2>/dev/null || echo "0")
            total_hospitals=$((total_hospitals + count))
            filename=$(basename "$file")
            printf "   %-40s %s hospitals\n" "$filename" "$count"
        fi
    done
    echo "   ────────────────────────────────────────────"
    echo "   Total:                                   $total_hospitals hospitals"
    echo ""
fi

echo "🎯 Next Steps:"
echo "1. Review the JSON files in $OUTPUT_DIR/"
echo "2. Import using: dart run scripts/import_osm_hospitals.dart"
echo "3. Verify import in Supabase dashboard"
echo ""
echo "💰 Cost: \$0 (100% FREE with OpenStreetMap!)"
echo ""
