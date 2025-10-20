import 'package:flutter/foundation.dart';

/// Data Source Configuration
///
/// Controls whether the app uses Supabase (online) or SQLite (offline) as the primary data source.
/// This allows easy switching between backends for development, testing, and production.
class DataSourceConfig {
  /// Primary data source type
  static DataSourceType get primaryDataSource => _primaryDataSource;
  static DataSourceType _primaryDataSource = DataSourceType.supabase;

  /// Fallback data source (used when primary fails)
  static DataSourceType get fallbackDataSource => _fallbackDataSource;
  static DataSourceType _fallbackDataSource = DataSourceType.sqlite;

  /// Whether to use Supabase as primary (default: true in production)
  static bool get useSupabase => _primaryDataSource == DataSourceType.supabase;

  /// Whether to use SQLite as primary (default: false, used for offline-first)
  static bool get useSQLite => _primaryDataSource == DataSourceType.sqlite;

  /// Whether to enable automatic fallback when primary source fails
  static bool get enableFallback => _enableFallback;
  static bool _enableFallback = true;

  /// Whether to sync data between Supabase and SQLite
  static bool get enableSync => _enableSync;
  static bool _enableSync = true;

  /// Configure the primary data source
  static void setPrimaryDataSource(DataSourceType type) {
    _primaryDataSource = type;
    if (kDebugMode) {
      print('📊 Primary data source: ${type.name}');
    }
  }

  /// Configure the fallback data source
  static void setFallbackDataSource(DataSourceType type) {
    _fallbackDataSource = type;
    if (kDebugMode) {
      print('📊 Fallback data source: ${type.name}');
    }
  }

  /// Enable or disable automatic fallback
  static void setEnableFallback(bool enabled) {
    _enableFallback = enabled;
    if (kDebugMode) {
      print('📊 Automatic fallback: ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Enable or disable data sync between sources
  static void setEnableSync(bool enabled) {
    _enableSync = enabled;
    if (kDebugMode) {
      print('📊 Data sync: ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Switch to Supabase-first mode (online-first)
  static void useSupabaseFirst() {
    setPrimaryDataSource(DataSourceType.supabase);
    setFallbackDataSource(DataSourceType.sqlite);
    setEnableFallback(true);
    setEnableSync(true);
    if (kDebugMode) {
      print('🌐 Switched to Supabase-first mode (online-first)');
    }
  }

  /// Switch to SQLite-first mode (offline-first)
  static void useSQLiteFirst() {
    setPrimaryDataSource(DataSourceType.sqlite);
    setFallbackDataSource(DataSourceType.supabase);
    setEnableFallback(true);
    setEnableSync(true);
    if (kDebugMode) {
      print('💾 Switched to SQLite-first mode (offline-first)');
    }
  }

  /// Switch to offline-only mode (no Supabase)
  static void useOfflineOnly() {
    setPrimaryDataSource(DataSourceType.sqlite);
    setEnableFallback(false);
    setEnableSync(false);
    if (kDebugMode) {
      print('📴 Switched to offline-only mode');
    }
  }

  /// Switch to online-only mode (no SQLite)
  static void useOnlineOnly() {
    setPrimaryDataSource(DataSourceType.supabase);
    setEnableFallback(false);
    setEnableSync(false);
    if (kDebugMode) {
      print('☁️ Switched to online-only mode');
    }
  }

  /// Print current configuration
  static void printConfig() {
    if (kDebugMode) {
      print('');
      print('╔════════════════════════════════════════════════╗');
      print('║  📊 DATA SOURCE CONFIGURATION                  ║');
      print('╚════════════════════════════════════════════════╝');
      print('  Primary:  ${_primaryDataSource.name}');
      print('  Fallback: ${_fallbackDataSource.name}');
      print('  Auto-fallback: ${_enableFallback ? "✓ Enabled" : "✗ Disabled"}');
      print('  Data sync: ${_enableSync ? "✓ Enabled" : "✗ Disabled"}');
      print('');
      print('  Mode: ${_getModeName()}');
      print('');
    }
  }

  static String _getModeName() {
    if (!_enableFallback && !_enableSync) {
      return _primaryDataSource == DataSourceType.supabase
          ? '☁️  Online-only'
          : '📴 Offline-only';
    } else if (_primaryDataSource == DataSourceType.supabase) {
      return '🌐 Online-first (Supabase primary, SQLite fallback)';
    } else {
      return '💾 Offline-first (SQLite primary, Supabase sync)';
    }
  }
}

/// Data source types
enum DataSourceType {
  /// Supabase backend (PostgreSQL, real-time, cloud)
  supabase,

  /// SQLite local database (offline, fast)
  sqlite,
}

/// Extension for DataSourceType
extension DataSourceTypeExtension on DataSourceType {
  /// Get the display name
  String get displayName {
    switch (this) {
      case DataSourceType.supabase:
        return 'Supabase (Cloud)';
      case DataSourceType.sqlite:
        return 'SQLite (Local)';
    }
  }

  /// Get the icon
  String get icon {
    switch (this) {
      case DataSourceType.supabase:
        return '☁️';
      case DataSourceType.sqlite:
        return '💾';
    }
  }
}
