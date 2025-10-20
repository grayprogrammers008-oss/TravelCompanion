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
      version: 5, // Bumped from 4 to 5 for checklists schema update
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

    if (oldVersion < 4) {
      // Fix itinerary_items table schema - remove old columns, add new ones
      try {
        // Rename old table
        await db.execute('ALTER TABLE itinerary_items RENAME TO itinerary_items_old');

        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE itinerary_items (
            id TEXT PRIMARY KEY,
            trip_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            location TEXT,
            start_time TEXT,
            end_time TEXT,
            day_number INTEGER,
            order_index INTEGER NOT NULL DEFAULT 0,
            created_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
            FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
          )
        ''');

        // Migrate data if any exists (map old date field to day_number)
        await db.execute('''
          INSERT INTO itinerary_items (
            id, trip_id, title, description, location,
            start_time, end_time, day_number, order_index,
            created_by, created_at, updated_at
          )
          SELECT
            id, trip_id, title, description, location,
            start_time, end_time, 1 as day_number, 0 as order_index,
            created_by, created_at, updated_at
          FROM itinerary_items_old
        ''');

        // Drop old table
        await db.execute('DROP TABLE itinerary_items_old');

        // Create indexes for performance
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_itinerary_items_trip_id ON itinerary_items(trip_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_itinerary_items_day_number ON itinerary_items(day_number)',
        );

        print('✅ Itinerary items table migrated to new schema');
      } catch (e) {
        print('Migration error (itinerary_items): $e');
      }
    }

    if (oldVersion < 5) {
      // Update checklists schema for collaborative features
      try {
        // Rename old tables
        await db.execute('ALTER TABLE checklists RENAME TO checklists_old');
        await db.execute('ALTER TABLE checklist_items RENAME TO checklist_items_old');

        // Create new checklists table with updated schema
        await db.execute('''
          CREATE TABLE checklists (
            id TEXT PRIMARY KEY,
            trip_id TEXT NOT NULL,
            name TEXT NOT NULL,
            created_by TEXT,
            created_at TEXT,
            updated_at TEXT,
            creator_name TEXT,
            FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
          )
        ''');

        // Create new checklist_items table with updated schema
        await db.execute('''
          CREATE TABLE checklist_items (
            id TEXT PRIMARY KEY,
            checklist_id TEXT NOT NULL,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            assigned_to TEXT,
            completed_by TEXT,
            completed_at TEXT,
            order_index INTEGER NOT NULL DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            assigned_to_name TEXT,
            completed_by_name TEXT,
            FOREIGN KEY (checklist_id) REFERENCES checklists (id) ON DELETE CASCADE
          )
        ''');

        // Migrate existing data if any
        await db.execute('''
          INSERT INTO checklists (
            id, trip_id, name, created_by, created_at, updated_at, creator_name
          )
          SELECT
            id, trip_id, title as name, created_by, created_at, updated_at, NULL as creator_name
          FROM checklists_old
        ''');

        await db.execute('''
          INSERT INTO checklist_items (
            id, checklist_id, title, is_completed, assigned_to,
            completed_by, completed_at, order_index, created_at, updated_at,
            assigned_to_name, completed_by_name
          )
          SELECT
            id, checklist_id, title, is_completed, assigned_to,
            NULL as completed_by, completed_at, 0 as order_index, created_at, updated_at,
            NULL as assigned_to_name, NULL as completed_by_name
          FROM checklist_items_old
        ''');

        // Drop old tables
        await db.execute('DROP TABLE checklist_items_old');
        await db.execute('DROP TABLE checklists_old');

        // Create indexes for performance
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_checklists_trip_id ON checklists(trip_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id ON checklist_items(checklist_id)',
        );

        print('✅ Checklists tables migrated to new schema');
      } catch (e) {
        print('Migration error (checklists): $e');
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
        start_time TEXT,
        end_time TEXT,
        day_number INTEGER,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for itinerary_items
    await db.execute(
      'CREATE INDEX idx_itinerary_items_trip_id ON itinerary_items(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_itinerary_items_day_number ON itinerary_items(day_number)',
    );

    // Create Checklists table with collaborative features
    await db.execute('''
      CREATE TABLE checklists (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        creator_name TEXT,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Create Checklist Items table with assignment and completion tracking
    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        checklist_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        assigned_to TEXT,
        completed_by TEXT,
        completed_at TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        assigned_to_name TEXT,
        completed_by_name TEXT,
        FOREIGN KEY (checklist_id) REFERENCES checklists (id) ON DELETE CASCADE
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
    await db.execute(
      'CREATE INDEX idx_checklists_trip_id ON checklists(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_checklist_items_checklist_id ON checklist_items(checklist_id)',
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
