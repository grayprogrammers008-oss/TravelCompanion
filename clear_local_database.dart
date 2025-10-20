// Clear Local Database Helper
// Run with: flutter run clear_local_database.dart
//
// This script clears the local SQLite database to fix "Email already exists" errors
// when the email doesn't actually exist in Supabase.

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  print('═' * 70);
  print('🗑️  CLEAR LOCAL DATABASE');
  print('═' * 70);
  print('');
  print('This script will clear the local SQLite database to fix');
  print('"Email already exists" errors.');
  print('');

  try {
    // Initialize FFI for desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    //Get database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'travel_crew.db');

    print('📂 Database location: $path');
    print('');

    // Check if database exists
    final dbFile = File(path);
    if (!await dbFile.exists()) {
      print('✅ No local database found!');
      print('   This means the local database is already clear.');
      print('   You can try signing up now.');
      print('');
      return;
    }

    print('📊 Database found. Checking contents...');
    print('');

    // Open database
    final db = await openDatabase(path);

    // Check profiles table
    try {
      final profiles = await db.query('profiles');
      print('Found ${profiles.length} profile(s) in local database:');
      print('');

      for (var profile in profiles) {
        print('   📧 ${profile['email']}');
        print('   🆔 ID: ${profile['id']}');
        print('   👤 Name: ${profile['full_name'] ?? 'Not set'}');
        print('   📅 Created: ${profile['created_at']}');
        print('');
      }

      if (profiles.isEmpty) {
        print('✅ Profiles table is already empty!');
        print('');
      }
    } catch (e) {
      print('⚠️  Could not read profiles table: $e');
      print('');
    }

    // Offer to clear
    print('═' * 70);
    print('🧹 CLEAR DATABASE');
    print('═' * 70);
    print('');
    print('Options:');
    print('  1. Delete ALL data (fresh start)');
    print('  2. Delete specific email (nithyaganesan53@gmail.com)');
    print('  3. Cancel (keep database as is)');
    print('');
    print('Enter your choice (1, 2, or 3):');

    final choice = stdin.readLineSync();

    if (choice == '1') {
      print('');
      print('🗑️  Deleting ALL local data...');
      print('');

      await db.close();
      await deleteDatabase(path);

      print('✅ SUCCESS! Local database completely deleted.');
      print('');
      print('Next steps:');
      print('  1. Restart the app');
      print('  2. Try signing up with nithyaganesan53@gmail.com');
      print('  3. The error should be gone!');
      print('');
    } else if (choice == '2') {
      print('');
      print('🗑️  Deleting nithyaganesan53@gmail.com...');
      print('');

      final deleted = await db.delete(
        'profiles',
        where: 'email = ?',
        whereArgs: ['nithyaganesan53@gmail.com'],
      );

      if (deleted > 0) {
        print('✅ SUCCESS! Deleted $deleted record(s).');
        print('');

        // Verify
        final remaining = await db.query('profiles');
        print('Remaining profiles: ${remaining.length}');
        print('');

        print('Next steps:');
        print('  1. Try signing up with nithyaganesan53@gmail.com');
        print('  2. The error should be gone!');
        print('');
      } else {
        print('ℹ️  Email not found in database.');
        print('   The "Email already exists" error must be from somewhere else.');
        print('');
      }

      await db.close();
    } else {
      print('');
      print('❌ Cancelled. Database not modified.');
      print('');
      await db.close();
    }

    print('═' * 70);
    print('✅ DONE');
    print('═' * 70);
    print('');

  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('═' * 70);
    print('💡 ALTERNATIVE SOLUTIONS');
    print('═' * 70);
    print('');
    print('If this script doesn\'t work, try:');
    print('');
    print('1. Clear app data manually:');
    print('   - Windows: Delete app data folder');
    print('   - Android: Settings → Apps → Travel Companion → Clear Data');
    print('   - iOS: Delete and reinstall app');
    print('   - Web: Browser DevTools → Clear Site Data');
    print('');
    print('2. Use a different email temporarily:');
    print('   - Try signing up with a test email');
    print('   - This confirms if it\'s email-specific or system-wide');
    print('');
    print('3. Check DataSourceConfig:');
    print('   - Verify you\'re in Online-Only mode');
    print('   - Check lib/core/config/data_source_config.dart');
    print('');
    print('4. Contact support with error details above');
    print('');
  }
}
