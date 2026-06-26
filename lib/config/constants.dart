/// App-wide constants for the Equeue application.
library;

// ─────────────────────────────────────────────────────────────────────────────
// APP META
// ─────────────────────────────────────────────────────────────────────────────

class AppMeta {
  AppMeta._();

  static const String appName = 'Equeue';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Queue Management System';
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPABASE
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseConfig {
  SupabaseConfig._();

  // TODO: Replace with your Supabase project URL
  static const String url = 'https://yxhusdhpjvphtoexcmdv.supabase.co';

  // TODO: Replace with your Supabase anon (public) key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4aHVzZGhwanZwaHRvZXhjbWR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MzE2ODEsImV4cCI6MjA5ODAwNzY4MX0.M29cLND_ScP-CwFzop_UmQYwPbe2D5NFJ2L5_Eldu5s';
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE NAMES
// ─────────────────────────────────────────────────────────────────────────────

class TableNames {
  TableNames._();

  static const String profiles = 'profiles';
  static const String branches = 'branches';
  static const String services = 'services';
  static const String tokens = 'tokens';
  static const String counters = 'counters';
  static const String notifications = 'notifications';
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUM → STRING MAPS
// ─────────────────────────────────────────────────────────────────────────────

/// Maps for serializing / deserializing enums to Supabase text columns.
class EnumMaps {
  EnumMaps._();

  static const Map<String, String> tokenStatus = {
    'waiting': 'waiting',
    'called': 'called',
    'serving': 'serving',
    'completed': 'completed',
    'cancelled': 'cancelled',
    'skipped': 'skipped',
    'no_show': 'no_show',
  };

  static const Map<String, String> tokenPriority = {
    'normal': 'normal',
    'emergency': 'emergency',
    'senior': 'senior',
    'pregnant': 'pregnant',
    'disabled': 'disabled',
  };

  static const Map<String, String> userRole = {
    'user': 'user',
    'admin': 'admin',
    'super_admin': 'super_admin',
  };

  static const Map<String, String> counterStatus = {
    'open': 'open',
    'closed': 'closed',
  };

  static const Map<String, String> notificationType = {
    'queue_update': 'queue_update',
    'turn_reminder': 'turn_reminder',
    'delay': 'delay',
    'completion': 'completion',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// DURATION CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class AppDurations {
  AppDurations._();

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration realtimePoll = Duration(seconds: 5);
  static const Duration snackbarDisplay = Duration(seconds: 3);
}
