import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';

/// Import OSM hospitals from JSON files into Supabase
///
/// Usage:
/// 1. Download hospital data using: ./scripts/import_south_india_hospitals.sh
/// 2. Update Supabase credentials below
/// 3. Run: dart run scripts/import_osm_hospitals.dart
void main() async {
  print('🏥 India Hospital Import to Supabase');
  print('============================================\n');

  // ⚠️ UPDATE THESE WITH YOUR SUPABASE CREDENTIALS
  const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

  if (supabaseUrl == 'YOUR_SUPABASE_URL') {
    print('❌ Error: Please update Supabase credentials in the script!');
    print('   Edit: scripts/import_osm_hospitals.dart');
    print('   Update: supabaseUrl and supabaseAnonKey\n');
    exit(1);
  }

  // Initialize Supabase client
  late SupabaseClient supabase;
  try {
    supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    print('✅ Connected to Supabase\n');
  } catch (e) {
    print('❌ Failed to connect to Supabase: $e\n');
    exit(1);
  }

  // States to import (All India)
  final states = [
    // South India
    {'name': 'tamil_nadu', 'display': 'Tamil Nadu'},
    {'name': 'karnataka', 'display': 'Karnataka'},
    {'name': 'kerala', 'display': 'Kerala'},
    {'name': 'andhra_pradesh', 'display': 'Andhra Pradesh'},
    // North India - States
    {'name': 'delhi', 'display': 'Delhi'},
    {'name': 'haryana', 'display': 'Haryana'},
    {'name': 'punjab', 'display': 'Punjab'},
    {'name': 'uttar_pradesh', 'display': 'Uttar Pradesh'},
    {'name': 'uttarakhand', 'display': 'Uttarakhand'},
    {'name': 'rajasthan', 'display': 'Rajasthan'},
    {'name': 'himachal_pradesh', 'display': 'Himachal Pradesh'},
    // North India - Union Territories
    {'name': 'jammu_kashmir', 'display': 'Jammu & Kashmir'},
    {'name': 'chandigarh', 'display': 'Chandigarh'},
    {'name': 'ladakh', 'display': 'Ladakh'},
    // East India - Major States
    {'name': 'west_bengal', 'display': 'West Bengal'},
    {'name': 'bihar', 'display': 'Bihar'},
    {'name': 'jharkhand', 'display': 'Jharkhand'},
    {'name': 'odisha', 'display': 'Odisha'},
    {'name': 'sikkim', 'display': 'Sikkim'},
    // East India - Northeast (Seven Sisters)
    {'name': 'assam', 'display': 'Assam'},
    {'name': 'arunachal_pradesh', 'display': 'Arunachal Pradesh'},
    {'name': 'nagaland', 'display': 'Nagaland'},
    {'name': 'manipur', 'display': 'Manipur'},
    {'name': 'mizoram', 'display': 'Mizoram'},
    {'name': 'tripura', 'display': 'Tripura'},
    {'name': 'meghalaya', 'display': 'Meghalaya'},
    // West India - States
    {'name': 'maharashtra', 'display': 'Maharashtra'},
    {'name': 'gujarat', 'display': 'Gujarat'},
    {'name': 'goa', 'display': 'Goa'},
    {'name': 'madhya_pradesh', 'display': 'Madhya Pradesh'},
    {'name': 'chhattisgarh', 'display': 'Chhattisgarh'},
    // West India - Union Territories
    {'name': 'dnh_dd', 'display': 'Dadra & Nagar Haveli and Daman & Diu'},
  ];

  int totalInserted = 0;
  int totalUpdated = 0;
  int totalFailed = 0;
  int totalSkipped = 0;

  for (final state in states) {
    final stateName = state['name']!;
    final stateDisplay = state['display']!;
    final filename = 'hospital_data/${stateName}_hospitals.json';
    final file = File(filename);

    if (!file.existsSync()) {
      print('⚠️  $stateDisplay: File not found - $filename');
      print('   Run: ./scripts/import_south_india_hospitals.sh first\n');
      continue;
    }

    print('📍 Processing $stateDisplay...');

    try {
      // Read JSON file
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);
      final elements = data['elements'] as List;

      print('   Found ${elements.length} hospitals in OSM data');

      // Parse OSM elements
      final hospitals = _parseOSMElements(elements);
      final validCount = hospitals.length;
      final skippedCount = elements.length - validCount;

      print('   Parsed $validCount valid hospitals');
      if (skippedCount > 0) {
        print('   Skipped $skippedCount invalid entries');
      }

      if (hospitals.isEmpty) {
        print('   ⚠️  No valid hospitals to import\n');
        totalSkipped += elements.length;
        continue;
      }

      // Batch import to database (in chunks of 100 for safety)
      const chunkSize = 100;
      int stateInserted = 0;
      int stateUpdated = 0;
      int stateFailed = 0;

      for (var i = 0; i < hospitals.length; i += chunkSize) {
        final end = (i + chunkSize < hospitals.length)
            ? i + chunkSize
            : hospitals.length;
        final chunk = hospitals.sublist(i, end);

        try {
          final response = await supabase.rpc(
            'batch_insert_osm_hospitals',
            params: {'hospitals_json': chunk},
          ) as List;

          final result = response.first as Map<String, dynamic>;
          final inserted = result['inserted_count'] as int;
          final updated = result['updated_count'] as int;
          final failed = result['failed_count'] as int;

          stateInserted += inserted;
          stateUpdated += updated;
          stateFailed += failed;

          print('   Batch ${(i ~/ chunkSize) + 1}: '
              '+$inserted new, ~$updated updated, ✗$failed failed');

          // Small delay between batches
          if (end < hospitals.length) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('   ❌ Batch ${(i ~/ chunkSize) + 1} error: $e');
          stateFailed += chunk.length;
        }
      }

      totalInserted += stateInserted;
      totalUpdated += stateUpdated;
      totalFailed += stateFailed;
      totalSkipped += skippedCount;

      print('   ──────────────────────────────');
      print('   Summary for $stateDisplay:');
      print('   ✅ Inserted: $stateInserted');
      print('   🔄 Updated: $stateUpdated');
      print('   ❌ Failed: $stateFailed\n');

      // Pause between states
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      print('   ❌ Error importing $stateDisplay: $e\n');
    }
  }

  print('============================================');
  print('📊 Final Summary:');
  print('   ✅ Total Inserted: $totalInserted');
  print('   🔄 Total Updated: $totalUpdated');
  print('   ❌ Total Failed: $totalFailed');
  print('   ⏭️  Total Skipped: $totalSkipped');
  print('   ════════════════════════════════');
  print('   📈 Total Processed: ${totalInserted + totalUpdated + totalFailed + totalSkipped}');
  print('============================================\n');

  if (totalInserted > 0 || totalUpdated > 0) {
    print('✅ Import successful!');
    print('   Check your Supabase dashboard to verify the data.\n');
  } else {
    print('⚠️  No hospitals were imported.');
    print('   Check the error messages above.\n');
  }

  exit(0);
}

/// Parse OSM elements to hospital format
List<Map<String, dynamic>> _parseOSMElements(List elements) {
  return elements
      .map((element) {
        try {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};

          // Get coordinates
          double? lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat'] as double?;
            lon = element['lon'] as double?;
          } else if (element['center'] != null) {
            lat = element['center']['lat'] as double?;
            lon = element['center']['lon'] as double?;
          }

          // Skip if no coordinates
          if (lat == null || lon == null) {
            return null;
          }

          // Skip if no name
          if (tags['name'] == null || (tags['name'] as String).trim().isEmpty) {
            return null;
          }

          return {
            'osm_id': element['id'].toString(),
            'osm_type': element['type'] as String,
            'name': tags['name'] as String,
            'phone': tags['phone'] ?? tags['contact:phone'],
            'address': _buildAddress(tags),
            'city': tags['addr:city'] ?? tags['addr:town'],
            'state': tags['addr:state'] ?? tags['addr:province'],
            'postcode': tags['addr:postcode'],
            'latitude': lat,
            'longitude': lon,
            'website': tags['website'] ?? tags['contact:website'],
            'amenity': tags['amenity'] ?? 'hospital',  // Add amenity field
            'emergency': tags['emergency'],
            'healthcare': tags['healthcare'],
            'beds': tags['beds'] != null ? int.tryParse(tags['beds'].toString()) : null,
            'operator': tags['operator'],
            'operator_type': tags['operator:type'],
            'opening_hours': tags['opening_hours'],
            'wheelchair': tags['wheelchair'],
            'specialties': _extractSpecialties(tags),
          };
        } catch (e) {
          // Skip invalid elements
          return null;
        }
      })
      .whereType<Map<String, dynamic>>()
      .toList();
}

String? _buildAddress(Map<String, dynamic> tags) {
  final parts = <String>[];

  if (tags['addr:housenumber'] != null) {
    parts.add(tags['addr:housenumber'].toString());
  }
  if (tags['addr:street'] != null) {
    parts.add(tags['addr:street'].toString());
  }
  if (tags['addr:suburb'] != null) {
    parts.add(tags['addr:suburb'].toString());
  }

  return parts.isEmpty ? null : parts.join(', ');
}

List<String>? _extractSpecialties(Map<String, dynamic> tags) {
  final specialties = <String>[];

  // Check various specialty tags
  if (tags['healthcare:speciality'] != null) {
    final spec = tags['healthcare:speciality'].toString();
    specialties.addAll(spec.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty));
  }

  // Add based on other tags
  if (tags['emergency'] == 'yes') specialties.add('Emergency');
  if (tags['healthcare:speciality:intensive_care'] == 'yes') {
    specialties.add('ICU');
  }
  if (tags['healthcare:speciality:cardiac'] == 'yes') {
    specialties.add('Cardiology');
  }
  if (tags['healthcare:speciality:trauma'] == 'yes') {
    specialties.add('Trauma');
  }

  return specialties.isEmpty ? null : specialties;
}
