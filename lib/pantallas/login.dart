import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/config/autenticacion.dart';
import 'package:eco_poli/pantallas/registro.dart';
import 'package:eco_poli/pantallas/bienvenido.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; 
import 'package:eco_poli/config/supabase.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // ── CONTROLADORES ─────────────────────────────────────────
  // Capturan lo que el usuario escribe en cada campo
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  // ── ESTADO ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>(); // Valida el formulario completo
  bool _cargando = false;                  // Muestra spinner en el botón
  bool _verContrasena = false;             // Alterna ojo abierto/cerrado

  final _servicioAuth = Autenticacion();
  String? _mensajeError; // null = sin error, texto = muestra el error
  
  // ── LIBERAR MEMORIA ───────────────────────────────────────
  // Siempre se llama cuando la pantalla se cierra
  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ── ACCIÓN DEL BOTÓN ──────────────────────────────────────

  Future<void> _handleLogin() async {
    setState(() => _mensajeError = null);    // Limpia error anterior si el usuario vuelve a intentar
    
    // Si algún campo falla la validación, se detiene aquí
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await _servicioAuth.iniciarSesion(
      correo: _correoController.text.trim(),
      contrasena: _contrasenaController.text.trim(),
    );

    setState(() => _cargando = false);

    if (error != null) {
      setState(() => _mensajeError = error);   // Hubo error: lo mostramos en pantalla
    
    } else {
      final authId = SupabaseConfig.client.auth.currentUser?.id;
      if (authId != null) {
        OneSignal.login(authId);
        debugPrint('✅ OneSignal vinculado al usuario: $authId');
      }
      // Login exitoso: navegamos a Bienvenido
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PantallaBienvenido(),
          ),
        );
      }
    }

  }

  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // Evita que el teclado tape los campos
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── LOGO ────────────────────────────────────
                Image.asset(
                  'recursos/logo2.png',
                  height: 210,
                ),
                const SizedBox(height: 48),

                // ── CAMPO CORREO ─────────────────────────────
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracionCampo(
                    hint: 'Correo',
                    icono: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── CAMPO CONTRASEÑA ─────────────────────────
                TextFormField(
                  controller: _contrasenaController,
                  obscureText: !_verContrasena, // oculta o muestra el texto
                  decoration: _decoracionCampo(
                    hint: 'Contraseña',
                    icono: Icons.lock_outline,
                  ).copyWith(
                    // Ojo para mostrar/ocultar contraseña
                    suffixIcon: IconButton(
                      icon: Icon(
                        _verContrasena
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: PaletaColores.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _verContrasena = !_verContrasena);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── BOTÓN INGRESAR ───────────────────────────
                _botonPrincipal(
                  texto: 'INGRESAR',
                  alPresionar: _handleLogin,
                ),
                const SizedBox(height: 20),

                // ── MENSAJE DE ERROR ─────────────────────────────────
                // Solo aparece si _mensajeError tiene texto
                if (_mensajeError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: PaletaColores.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: PaletaColores.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                          color: PaletaColores.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _mensajeError!,
                            style: TextStyle(
                              color: PaletaColores.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── ENLACE REGISTRO ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(color: PaletaColores.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        // navegación al registro
                        debugPrint('→ Ir a Registro');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PantallaRegistro(),
                          ),
                        );
                      },
                      child: Text(
                        'Regístrate',
                        style: TextStyle(
                          color: PaletaColores.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── ILUSTRACIÓN DECORATIVA ───────────────────
                Image.asset(
                  'recursos/decoracion.png',
                  height: 210,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  // MÉTODOS PRIVADOS DE UI
  // ════════════════════════════════════════════════════════

  /// Estilo base para todos los campos de texto
  InputDecoration _decoracionCampo({
    required String hint,
    required IconData icono,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: PaletaColores.textSecondary,
        fontSize: 14,
      ),
      suffixIcon: Icon(icono, color: PaletaColores.textSecondary),
      filled: true,
      fillColor: PaletaColores.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PaletaColores.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PaletaColores.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PaletaColores.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  /// Botón principal verde con estado de carga
  Widget _botonPrincipal({
    required String texto,
    required Future<void> Function() alPresionar,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletaColores.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PaletaColores.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _cargando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}