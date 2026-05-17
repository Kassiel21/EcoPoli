import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/modelos/bar_modelo.dart';

class BaresRepositorio {
  final _client = SupabaseConfig.client;
  List<BarModelo>? _cache;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  /// Obtiene todos los bares desde Supabase
  Future<List<BarModelo>> obtenerBares() async {
    try {
      final response = await _client
          .from('bares')
          .select()
          .order('fecha_creacion', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final bares = (response as List)
          .map((data) => BarModelo.fromMap(data as Map<String, dynamic>))
          .toList();

      _cache = bares;
      _cacheTimestamp = DateTime.now();

      return bares;
    } catch (e) {
      if (_cache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cache!;
      }
      rethrow;
    }
  }

  /// Obtiene solo los bares activos desde Supabase (estado_bar = true)
  Future<List<BarModelo>> obtenerBaresActivos() async {
    try {
      final response = await _client
          .from('bares')
          .select()
          .eq('estado_bar', true)
          .order('fecha_creacion', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final bares = (response as List)
          .map((data) => BarModelo.fromMap(data as Map<String, dynamic>))
          .toList();

      _cache = bares;
      _cacheTimestamp = DateTime.now();

      return bares;
    } catch (e) {
      if (_cache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cache!;
      }
      rethrow;
    }
  }

  /// Obtiene un bar por su ID
  Future<BarModelo?> obtenerBarPorId(String idBar) async {
    try {
      final response = await _client
          .from('bares')
          .select()
          .eq('id_bar', idBar)
          .single();

      return BarModelo.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Refresca los bares desde Supabase (limpia cache)
  Future<List<BarModelo>> refrescarBares() async {
    limpiarCache();
    return obtenerBaresActivos();
  }

  /// Limpia el cache
  void limpiarCache() {
    _cache = null;
    _cacheTimestamp = null;
  }
}