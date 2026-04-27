import 'package:supabase_flutter/supabase_flutter.dart';

/// Punto de acceso único a Supabase en toda la app.

class SupabaseConfig {
  SupabaseConfig._();

  // Tus credenciales del proyecto
  static const String _url = 'https://bjrfmivzrbfdojkwleat.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqcmZtaXZ6cmJmZG9qa3dsZWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNTMzNjAsImV4cCI6MjA5MjYyOTM2MH0.IPu8gmuYAQVsd1wSd643x4nyd95XiIbntdTsKTm_dYo';

  /// Inicializa Supabase. Se llama UNA sola vez al arrancar la app.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  /// Acceso rápido al cliente desde cualquier parte de la app.
  /// Uso: SupabaseConfig.client.from('usuarios')...
  static SupabaseClient get client => Supabase.instance.client;
}