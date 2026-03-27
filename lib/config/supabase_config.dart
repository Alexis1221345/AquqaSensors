import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = 'https://ehpzgyqfuaytlbwplapi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocHpneXFmdWF5dGxid3BsYXBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNTQ4MjcsImV4cCI6MjA4NzgzMDgyN30.80raAW2Z38jgj6kex06ya7yiCzeyTtEkApv-pU4zVAo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}