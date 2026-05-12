import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/modelos/usuario_modelo.dart';

/// Repositorio que centraliza todas las operaciones de perfil contra Supabase.
/// Separa la lógica de datos de la capa de UI.
class PerfilRepositorio {
  final _supabase = SupabaseConfig.client;

  // ── OBTENER PERFIL ─────────────────────────────────────────────────────────

  /// Retorna el [UsuarioModelo] del usuario actualmente autenticado.
  /// Lanza [Exception] si no hay sesión activa o falla la consulta.
  Future<UsuarioModelo> obtenerPerfil() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) throw Exception('No hay sesión activa');

    final respuesta = await _supabase
        .from('usuarios')
        .select()
        .eq('auth_id', authId)
        .single();

    return UsuarioModelo.fromMap(respuesta);
  }

  // ── ACTUALIZAR NOMBRE ──────────────────────────────────────────────────────

  /// Actualiza el nombre del usuario en la tabla `usuarios`.
  /// Retorna null si fue exitoso, o un mensaje de error.
  Future<String?> actualizarNombre(String nuevoNombre) async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return 'No hay sesión activa';

      await _supabase
          .from('usuarios')
          .update({'nombre': nuevoNombre.trim()})
          .eq('auth_id', authId);

      return null; // null = éxito
    } on PostgrestException catch (e) {
      debugPrint('❌ Error actualizando nombre: ${e.message}');
      return 'Error al guardar el nombre. Intenta de nuevo.';
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  // ── ACTUALIZAR UBICACIÓN ───────────────────────────────────────────────────

  /// Actualiza ciudad y dirección del usuario.
  /// Retorna null si fue exitoso, o un mensaje de error.
  Future<String?> actualizarUbicacion({
    required String ciudad,
    required String direccion,
  }) async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return 'No hay sesión activa';

      await _supabase
          .from('usuarios')
          .update({
            'ciudad': ciudad.trim(),
            'direccion': direccion.trim(),
          })
          .eq('auth_id', authId);

      return null;
    } on PostgrestException catch (e) {
      debugPrint('❌ Error actualizando ubicación: ${e.message}');
      return 'Error al guardar la ubicación. Intenta de nuevo.';
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  // ── ACTUALIZAR FOTO DE PERFIL ──────────────────────────────────────────────

  /// Sube la imagen al bucket `fotos-perfil` de Supabase Storage
  /// y actualiza la URL en la tabla `usuarios`.
  /// Retorna la URL pública si fue exitoso, o lanza [Exception].
  Future<String> subirFotoPerfil(File imagen) async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) throw Exception('No hay sesión activa');

    // Nombre único para evitar colisiones en el bucket
    final extension = imagen.path.split('.').last;
    final rutaArchivo = 'perfil/$authId.$extension';

    // Subir al bucket (upsert = reemplaza si ya existe)
    await _supabase.storage
        .from('fotos-perfil')
        .upload(rutaArchivo, imagen, fileOptions: const FileOptions(upsert: true));

    // Obtener URL pública
    final urlPublica = _supabase.storage
        .from('fotos-perfil')
        .getPublicUrl(rutaArchivo);

    // Guardar URL en la tabla usuarios
    await _supabase
        .from('usuarios')
        .update({'foto_perfil': urlPublica})
        .eq('auth_id', authId);

    return urlPublica;
  }

  /// Elimina la foto de perfil del usuario (pone null en la BD).
  Future<String?> eliminarFotoPerfil() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return 'No hay sesión activa';

      await _supabase
          .from('usuarios')
          .update({'foto_perfil': null})
          .eq('auth_id', authId);

      return null;
    } catch (e) {
      debugPrint('❌ Error eliminando foto: $e');
      return 'Error al eliminar la foto.';
    }
  }
}
