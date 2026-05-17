import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/modelos/producto_modelo.dart';

/// Repositorio que centraliza todas las operaciones de productos contra Supabase.
/// Separa la lógica de datos de la capa de UI.
class ProductosRepositorio {
  final _supabase = SupabaseConfig.client;
  List<ProductoModelo>? _cacheProductos;

  /// Obtiene todos los productos disponibles (stock > 0) desde Supabase.
  /// Usa cache simple en memoria para evitar consultas repetidas.
  Future<List<ProductoModelo>> obtenerTodosLosProductos() async {
    if (_cacheProductos != null) {
      return _cacheProductos!;
    }

    try {
      final respuesta = await _supabase
          .from('productos')
          .select()
          .gt('stock', 0);

      if (respuesta.isEmpty) {
        return [];
      }

      _cacheProductos = respuesta
          .map((producto) => ProductoModelo.fromMap(producto))
          .toList();
      return _cacheProductos!;
    } on PostgrestException catch (e) {
      debugPrint('❌ Error obteniendo productos: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return [];
    }
  }

  /// Selecciona aleatoriamente 1 o 2 productos de la lista de productos disponibles.
  /// Lógica temporal para mostrar productos en bares sin relación directa en base de datos.
  List<ProductoModelo> seleccionarProductosAleatorios(List<ProductoModelo> productos) {
    if (productos.isEmpty) return [];

    final random = Random();
    final cantidad = random.nextBool() ? 1 : 2;
    
    if (productos.length <= cantidad) {
      return productos;
    }

    final productosMezclados = List<ProductoModelo>.from(productos);
    productosMezclados.shuffle(random);
    
    return productosMezclados.take(cantidad).toList();
  }

  /// Limpia el cache de productos (útil para forzar recarga).
  void limpiarCache() {
    _cacheProductos = null;
  }
}