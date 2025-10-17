import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// SQLite Database Helper for local development
/// This replaces Supabase during development phase
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_crew.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, filePath);

    return await openDatabase(
      dbPath,
      version: 3, // Bumped from 2 to 3 for trip_invites table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add transaction_date column if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE expenses ADD COLUMN transaction_date TEXT',
        );
      } catch (e) {
        // Column might already exist, ignore error
        print('Migration note: $e');
      }
    }

    if (oldVersion < 3) {
      // Add trip_invites table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS trip_invites (
            id TEXT PRIMARY KEY,
            trip_id TEXT NOT NULL,
            invited_by TEXT NOT NULL,
            email TEXT NOT NULL,
            phone_number TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            invite_code TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
            FOREIGN KEY (invited_by) REFERENCES profiles (id) ON DELETE CASCADE
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_trip_invites_trip_id ON trip_invites(trip_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_trip_invites_invite_code ON trip_invites(invite_code)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_trip_invites_email ON trip_invites(email)',
        );

        print('✅ Trip invites table created');
      } catch (e) {
        print('Migration error (trip_invites): $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Users/Profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT,
        phone_number TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create auth_sessions table to track login sessions
    await db.execute('''
      CREATE TABLE auth_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Trips table
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        destination TEXT,
        start_date TEXT,
        end_date TEXT,
        cover_image_url TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Trip Members table
    await db.execute('''
      CREATE TABLE trip_members (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE,
        UNIQUE(trip_id, user_id)
      )
    ''');

    // Create Itinerary Items table
    await db.execute('''
      CREATE TABLE itinerary_items (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        category TEXT,
        notes TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Checklists table
    await db.execute('''
      CREATE TABLE checklists (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Checklist Items table
    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        checklist_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        assigned_to TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (checklist_id) REFERENCES checklists (id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to) REFERENCES profiles (id) ON DELETE SET NULL
      )
    ''');

    // Create Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'INR',
        category TEXT,
        paid_by TEXT NOT NULL,
        split_type TEXT NOT NULL DEFAULT 'equal',
        receipt_url TEXT,
        transaction_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (paid_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Expense Splits table
    await db.execute('''
      CREATE TABLE expense_splits (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        settled_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE,
        UNIQUE(expense_id, user_id)
      )
    ''');

    // Create Settlements table
    await db.execute('''
      CREATE TABLE settlements (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        from_user TEXT NOT NULL,
        to_user TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'INR',
        payment_method TEXT,
        payment_proof_url TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        transaction_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (from_user) REFERENCES profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (to_user) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create Trip Invites table
    await db.execute('''
      CREATE TABLE trip_invites (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        invited_by TEXT NOT NULL,
        email TEXT NOT NULL,
        phone_number TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        invite_code TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (invited_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_trip_members_trip_id ON trip_members(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_trip_members_user_id ON trip_members(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_itinerary_trip_id ON itinerary_items(trip_id)',
    );
    await db.execute('CREATE INDEX idx_expenses_trip_id ON expenses(trip_id)');
    await db.execute(
      'CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id)',
    );
    await db.execute(
      'CREATE INDEX idx_settlements_trip_id ON settlements(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_trip_invites_trip_id ON trip_invites(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_trip_invites_invite_code ON trip_invites(invite_code)',
    );
    await db.execute(
      'CREATE INDEX idx_trip_invites_email ON trip_invites(email)',
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('settlements');
    await db.delete('expense_splits');
    await db.delete('expenses');
    await db.delete('checklist_items');
    await db.delete('checklists');
    await db.delete('itinerary_items');
    await db.delete('trip_members');
    await db.delete('trips');
    await db.delete('auth_sessions');
    await db.delete('profiles');
  }

  /// Delete database (for complete reset)
  Future<void> deleteDatabase() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, 'travel_crew.db');
    final File dbFile = File(dbPath);

    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    _database = null;
  }
}
