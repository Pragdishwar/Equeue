import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton helper for accessing the Supabase client throughout the app.
///
/// Provides convenient static getters so services never need to call
/// `Supabase.instance.client` directly.
class SupabaseService {
  SupabaseService._();

  /// The underlying [SupabaseClient] instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the GoTrue auth client.
  static GoTrueClient get auth => client.auth;

  /// Returns a [SupabaseQueryBuilder] for the given table [name].
  static SupabaseQueryBuilder table(String name) => client.from(name);

  /// Returns a [RealtimeChannel] with the given [name].
  static RealtimeChannel channel(String name) => client.channel(name);

  /// The currently authenticated user, or `null`.
  static User? get currentUser => auth.currentUser;

  /// The current session, or `null`.
  static Session? get currentSession => auth.currentSession;
}
