/// Database Configuration
///
/// Controls which database backend to use.
/// Set [useSupabase] to true for production, false for local SQLite testing.
class DatabaseConfig {
  // Switch this flag to toggle between SQLite (false) and Supabase (true)
  static const bool useSupabase = false;

  // SQLite database name
  static const String sqliteDatabaseName = 'travel_crew.db';
  static const int sqliteDatabaseVersion = 1;
}
