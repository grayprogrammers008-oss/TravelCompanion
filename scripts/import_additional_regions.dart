import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';

/// Import additional North India regions (Jammu & Kashmir, Chandigarh, Ladakh)
void main() async {
  print('🏥 Additional North India Regions Import');
  print('============================================\n');

  const supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';

  late SupabaseClient supabase;
  try {
    supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    print('✅ Connected to Supabase\n');
  } catch (e) {
    print('❌ Failed to connect: $e\n');
    exit(1);
  }

  final regions = [
    {'name': 'jammu_kashmir', 'display': 'Jammu & Kashmir'},
    {'name': 'chandigarh', 'display': 'Chandigarh'},
    {'name': 'ladakh', 'display': 'Ladakh'},
  ];

  int totalInserted = 0;
  int totalUpdated = 0;
  int totalFailed = 0;
  int totalSkipped = 0;

  for (final region in regions) {
    final regionName = region['name']!;
    final regionDisplay = region['display']!;
    final filename = 'hospital_data/${regionName}_hospitals.json';
    final file = File(filename);

    if (!file.existsSync()) {
      print('⚠️  $regionDisplay: File not found - $filename\n');
      continue;
    }

    print('📍 Processing $regionDisplay...');

    try {
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);
      final elements = data['elements'] as List;

      final hospitals = _parseOSMElements(elements);
      print('   Found ${elements.length} hospitals in OSM data');
      print('   Parsed ${hospitals.length} valid hospitals');

      if (hospitals.isEmpty) {
        print('   ⚠️  No valid hospitals\n');
        totalSkipped += elements.length;
        continue;
      }

      const chunkSize = 100;
      int regionInserted = 0;
      int regionUpdated = 0;
      int regionFailed = 0;

      for (var i = 0; i < hospitals.length; i += chunkSize) {
        final end = (i + chunkSize < hospitals.length) ? i + chunkSize : hospitals.length;
        final chunk = hospitals.sublist(i, end);

        try {
          final response = await supabase.rpc(
            'batch_insert_osm_hospitals',
            params: {'hospitals_json': chunk},
          ) as List;

          final result = response.first as Map<String, dynamic>;
          regionInserted += result['inserted_count'] as int;
          regionUpdated += result['updated_count'] as int;
          regionFailed += result['failed_count'] as int;

          print('   Batch ${(i ~/ chunkSize) + 1}: ✓');
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('   ❌ Batch ${(i ~/ chunkSize) + 1} error: $e');
          regionFailed += chunk.length;
        }
      }

      totalInserted += regionInserted;
      totalUpdated += regionUpdated;
      totalFailed += regionFailed;
      totalSkipped += (elements.length - hospitals.length);

      print('   ✅ $regionDisplay: $regionInserted inserted\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  print('============================================');
  print('📊 Summary:');
  print('   ✅ Inserted: $totalInserted');
  print('   🔄 Updated: $totalUpdated');
  print('   ❌ Failed: $totalFailed');
  print('   ⏭️  Skipped: $totalSkipped');
  print('============================================\n');
}

List<Map<String, dynamic>> _parseOSMElements(List elements) {
  return elements.map((element) {
    try {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};

      double? lat, lon;
      if (element['type'] == 'node') {
        lat = element['lat'] as double?;
        lon = element['lon'] as double?;
      } else if (element['center'] != null) {
        lat = element['center']['lat'] as double?;
        lon = element['center']['lon'] as double?;
      }

      if (lat == null || lon == null) return null;
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
        'amenity': tags['amenity'] ?? 'hospital',
        'emergency': tags['emergency'],
        'healthcare': tags['healthcare'],
        'beds': tags['beds'] != null ? int.tryParse(tags['beds'].toString()) : null,
        'operator': tags['operator'],
        'operator_type': tags['operator:type'],
      };
    } catch (e) {
      return null;
    }
  }).whereType<Map<String, dynamic>>().toList();
}

String? _buildAddress(Map<String, dynamic> tags) {
  final parts = <String>[];
  if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber'].toString());
  if (tags['addr:street'] != null) parts.add(tags['addr:street'].toString());
  if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb'].toString());
  return parts.isEmpty ? null : parts.join(', ');
}
