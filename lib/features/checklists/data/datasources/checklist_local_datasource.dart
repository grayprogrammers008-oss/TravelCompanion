import 'package:sqflite/sqflite.dart';
import '../../../../shared/models/checklist_model.dart';
import '../../../../core/database/database_helper.dart';

/// Local data source for checklists using SQLite
class ChecklistLocalDataSource {
  final DatabaseHelper _databaseHelper;

  ChecklistLocalDataSource(this._databaseHelper);

  /// Get database instance
  Future<Database> get _database async => await _databaseHelper.database;

  /// Initialize checklist tables
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklists (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        creator_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklist_items (
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
        FOREIGN KEY (checklist_id) REFERENCES checklists(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_checklists_trip_id
      ON checklists(trip_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id
      ON checklist_items(checklist_id)
    ''');
  }

  /// Get all checklists for a trip
  Future<List<ChecklistModel>> getTripChecklists(String tripId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checklists',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => ChecklistModel.fromJson(map)).toList();
  }

  /// Get a specific checklist
  Future<ChecklistModel?> getChecklist(String checklistId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checklists',
      where: 'id = ?',
      whereArgs: [checklistId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ChecklistModel.fromJson(maps.first);
  }

  /// Get checklist items
  Future<List<ChecklistItemModel>> getChecklistItems(String checklistId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checklist_items',
      where: 'checklist_id = ?',
      whereArgs: [checklistId],
      orderBy: 'order_index ASC, created_at ASC',
    );

    return maps.map((map) => ChecklistItemModel.fromJson(map)).toList();
  }

  /// Get a single checklist item by ID
  Future<ChecklistItemModel?> getChecklistItem(String itemId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checklist_items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ChecklistItemModel.fromJson(maps.first);
  }

  /// Insert or update checklist
  Future<void> upsertChecklist(ChecklistModel checklist) async {
    final db = await _database;
    await db.insert(
      'checklists',
      checklist.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update checklist item
  Future<void> upsertChecklistItem(ChecklistItemModel item) async {
    final db = await _database;
    final Map<String, dynamic> json = item.toJson();
    // Convert bool to int for SQLite
    json['is_completed'] = item.isCompleted ? 1 : 0;

    await db.insert(
      'checklist_items',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch insert/update checklists
  Future<void> upsertChecklists(List<ChecklistModel> checklists) async {
    final db = await _database;
    final Batch batch = db.batch();
    for (final checklist in checklists) {
      batch.insert(
        'checklists',
        checklist.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Batch insert/update checklist items
  Future<void> upsertChecklistItems(List<ChecklistItemModel> items) async {
    final db = await _database;
    final Batch batch = db.batch();
    for (final item in items) {
      final Map<String, dynamic> json = item.toJson();
      json['is_completed'] = item.isCompleted ? 1 : 0;

      batch.insert(
        'checklist_items',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Delete checklist
  Future<void> deleteChecklist(String checklistId) async {
    final db = await _database;
    // Items will be deleted automatically due to CASCADE
    await db.delete(
      'checklists',
      where: 'id = ?',
      whereArgs: [checklistId],
    );
  }

  /// Delete checklist item
  Future<void> deleteChecklistItem(String itemId) async {
    final db = await _database;
    await db.delete(
      'checklist_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Delete all checklists for a trip
  Future<void> deleteTripChecklists(String tripId) async {
    final db = await _database;
    await db.delete(
      'checklists',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  /// Clear all checklists
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('checklist_items');
    await db.delete('checklists');
  }
}
