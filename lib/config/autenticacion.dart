import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:eco_poli/config/paleta_colores.dart';

class Autenticacion {
  // Acceso al cliente de Supabase
  final _supabase = Supabase.instance.client;

  // ── LOGIN ──────────────────────────────────────────────
  /// Inicia sesión con correo y contraseña.
  /// Retorna null si todo salió bien.
  /// Retorna un mensaje de error si algo falló.
  
  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );
      return null; // null = éxito, sin errores

    } on AuthException catch (e) {
      // Error propio de Supabase (credenciales incorrectas, etc.)
      return _traducirError(e.message);

    } catch (e) {
      // Error inesperado (sin internet, tiempo de espera, etc.)
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  Future<String?> registrarUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String contrasena,
  }) async {
    try {
      //Crear el usuario en Supabase Auth
      // Esto genera el auth_id que necesita tu tabla usuarios
      
      debugPrint('🚀 Iniciando registro: $correo');
      final respuesta = await _supabase.auth.signUp(
        email: correo,
        password: contrasena,
        emailRedirectTo: 'io.supabase.ecopoli://login-callback',
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'cedula': cedula,
        }
      );

      debugPrint('✅ Auth OK - User ID: ${respuesta.user?.id}');
      // Si no se creó el usuario por alguna razón
      if (respuesta.user == null) {
        return 'No se pudo crear el usuario. Intenta de nuevo.';
      }
      return  null;

      /*debugPrint('🚀 Insertando en tabla usuarios...');
      // PASO B: Guardar datos adicionales en tu tabla usuarios
      // El auth_id viene del usuario recién creado en Supabase Auth
      await _supabase.from('usuarios').insert({
        'auth_id': respuesta.user!.id,
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'correo': correo,
        'rol': 'estudiante',       // rol por defecto según tu BD
        'cant_puntos': 0,          // inicia en 0
        'estado_usuario': true,
      });

      debugPrint('✅ Insert OK');
      return null; // null = éxito */

    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');
      return _traducirError(e.message);

    } on PostgrestException catch (e) {
      // errores específicos de la base de datos
      debugPrint('❌ PostgrestException: ${e.message}');
      debugPrint('❌ Código: ${e.code}');
      debugPrint('❌ Detalle: ${e.details}');

      if (e.code == '23505') {
        if (e.message.contains('cedula')) {
          return 'Ya existe una cuenta con esa cédula.';
        }
        if (e.message.contains('correo')) {
          return 'Ya existe una cuenta con ese correo.';
        }
        return 'Ese usuario ya está registrado.';
      }

      return 'Error en base de datos: ${e.message}';

      } /*catch (e) {
        return 'Error de conexión. Verifica tu internet.';
      }*/
  }

  // ── CERRAR SESIÓN ──────────────────────────────────────
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  // ── USUARIO ACTUAL ─────────────────────────────────────
  /// Retorna el usuario logueado, o null si no hay sesión activa
  User? get usuarioActual => _supabase.auth.currentUser;

  // ── TRADUCIR ERRORES ───────────────────────────────────
  
  String _traducirError(String mensaje) {
    if (mensaje.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (mensaje.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo antes de ingresar.';
    }
    if (mensaje.contains('Too many requests')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  Future<String> obtenerNombreUsuario() async {
    try {
      // Obtenemos el auth_id del usuario logueado
      final authId = _supabase.auth.currentUser?.id;
      debugPrint('🔍 Buscando nombre para auth_id: $authId');
      
      if (authId == null) return 'Usuario';

      // Consultamos la tabla usuarios filtrando por auth_id
      final respuesta = await _supabase
          .from('usuarios')
          .select('nombre')
          .eq('auth_id', authId)
          .single(); // esperamos un solo resultado

      return respuesta['nombre'] ?? 'Usuario';

    } catch (e) {
      debugPrint('❌ Error obteniendo nombre: $e');
      debugPrint('❌ Tipo: ${e.runtimeType}');
  if (e is PostgrestException) {
    debugPrint('❌ Código Postgrest: ${e.code}');
    debugPrint('❌ Detalle: ${e.details}');
  }
      return 'Usuario'; // valor por defecto si algo falla
    }
  }

}