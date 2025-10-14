import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/database_config.dart';

/// SQLite Database Helper
///
/// Manages SQLite database connection and schema creation
class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  static Database? _database;

  factory SQLiteHelper() => _instance;

  SQLiteHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConfig.sqliteDatabaseName);

    return await openDatabase(
      path,
      version: DatabaseConfig.sqliteDatabaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT,
        avatar_url TEXT,
        phone TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        destination TEXT,
        start_date INTEGER,
        end_date INTEGER,
        cover_image_url TEXT,
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE trip_members (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        joined_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(trip_id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE itinerary_items (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        activity_type TEXT DEFAULT 'activity',
        start_time INTEGER,
        end_time INTEGER,
        day_number INTEGER NOT NULL,
        order_index INTEGER DEFAULT 0,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklists (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT DEFAULT 'general',
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        checklist_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        assigned_to TEXT,
        completed_by TEXT,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (checklist_id) REFERENCES checklists (id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL,
        FOREIGN KEY (completed_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'INR',
        paid_by TEXT NOT NULL,
        category TEXT DEFAULT 'other',
        description TEXT,
        expense_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (paid_by) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_splits (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        is_settled INTEGER DEFAULT 0,
        FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(expense_id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settlements (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        from_user TEXT NOT NULL,
        to_user TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'INR',
        payment_method TEXT,
        transaction_id TEXT,
        notes TEXT,
        settled_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (from_user) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (to_user) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_trips_created_by ON trips(created_by)');
    await db.execute(
      'CREATE INDEX idx_trip_members_trip ON trip_members(trip_id)',
    );
    await db.execute(
      'CREATE INDEX idx_trip_members_user ON trip_members(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_itinerary_trip ON itinerary_items(trip_id)',
    );
    await db.execute('CREATE INDEX idx_checklists_trip ON checklists(trip_id)');
    await db.execute(
      'CREATE INDEX idx_checklist_items_checklist ON checklist_items(checklist_id)',
    );
    await db.execute('CREATE INDEX idx_expenses_trip ON expenses(trip_id)');
    await db.execute(
      'CREATE INDEX idx_expense_splits_expense ON expense_splits(expense_id)',
    );
    await db.execute(
      'CREATE INDEX idx_settlements_trip ON settlements(trip_id)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConfig.sqliteDatabaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
