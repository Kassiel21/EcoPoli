import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/servicios/autenticacion.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  // ── CONTROLADORES ────────────────────────────────────────
  final _nombreController      = TextEditingController();
  final _apellidoController    = TextEditingController();
  final _cedulaController      = TextEditingController();
  final _correoController      = TextEditingController();
  final _contrasenaController  = TextEditingController();
  final _confirmarController   = TextEditingController();

  // ── ESTADO ───────────────────────────────────────────────
  final _formKey       = GlobalKey<FormState>();
  final _servicioAuth  = Autenticacion();
  bool _cargando       = false;
  bool _verContrasena  = false;
  bool _verConfirmar   = false;
  String? _mensajeError;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // ── ACCIÓN REGISTRO ──────────────────────────────────────
  Future<void> _handleRegistro() async {
    setState(() => _mensajeError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await _servicioAuth.registrarUsuario(
      nombre:     _nombreController.text.trim(),
      apellido:   _apellidoController.text.trim(),
      cedula:     _cedulaController.text.trim(),
      correo:     _correoController.text.trim(),
      contrasena: _contrasenaController.text.trim(),
    );

    setState(() => _cargando = false);

    if (error != null) {
      setState(() => _mensajeError = error);
    } else {
      // Registro exitoso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            title: Row(
              children: [
                Icon(Icons.mark_email_read_outlined,
                  color: PaletaColores.primary),
                const SizedBox(width: 8),
                const Text('¡Revisa tu correo!'),
              ],
            ),

            content: const Text(
              'Te enviamos un enlace de verificación. '
              'Ábrelo desde tu celular para activar tu cuenta.',
              style: TextStyle(fontSize: 14),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // cierra el diálogo
                  Navigator.pop(context); // regresa al login
                },
                child: Text(
                  'Entendido',
                  style: TextStyle(color: PaletaColores.primary),
                ),
              ),
            ],
          ),
        );
      }
      //debugPrint('✅ Registro exitoso');
    }
  }

  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      // Flecha de regreso al Login
      appBar: AppBar(
        backgroundColor: PaletaColores.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
            color: PaletaColores.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(   //tipo marca de agua
            bottom: -150,
            left: 0,
            right: 0,
            child: Image.asset(
              'recursos/decoracion.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── TÍTULO ───────────────────────────────────
                    Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: PaletaColores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── CAMPO NOMBRE ─────────────────────────────
                    TextFormField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoracionCampo(
                        hint: 'Nombre',
                        icono: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── CAMPO APELLIDO ───────────────────────────
                    TextFormField(
                      controller: _apellidoController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoracionCampo(
                        hint: 'Apellido',
                        icono: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── CAMPO CÉDULA ─────────────────────────────
                    TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      maxLength: 10, // cédula ecuatoriana = 10 dígitos
                      decoration: _decoracionCampo(
                        hint: 'Cédula',
                        icono: Icons.badge_outlined,
                      ).copyWith(
                        counterText: '', // oculta el contador de caracteres
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu cédula';
                        }
                        if (value.length != 10) {
                          return 'La cédula debe tener 10 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── CAMPO CORREO ─────────────────────────────
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoracionCampo(
                        hint: 'Correo',
                        icono: Icons.email_outlined,
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
                      obscureText: !_verContrasena,
                      decoration: _decoracionCampo(
                        hint: 'Contraseña',
                        icono: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verContrasena
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                            color: PaletaColores.textSecondary,
                          ),
                          onPressed: () =>
                            setState(() => _verContrasena = !_verContrasena),
                        ),
                        errorMaxLines: 3,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        
                        final List<String> faltantes = [];   //requisitos para la contraseña
                        if (value.length < 6) {
                          faltantes.add('minimo 6 caracteres');
                        }
                        if (!value.contains(RegExp(r'[a-z]'))) {
                          faltantes.add('una minúscula');
                        }
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          faltantes.add('una mayúscula');
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          faltantes.add('un número');
                        }
                        if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                          faltantes.add('un carácter especial (!@#\$...)');
                        }
                        //muestra lo que falta a la contra
                        if (faltantes.isNotEmpty) {
                          return 'La contraseña debe tener: ${faltantes.join(', ')}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── CAMPO CONFIRMAR CONTRASEÑA ───────────────
                    TextFormField(
                      controller: _confirmarController,
                      obscureText: !_verConfirmar,
                      decoration: _decoracionCampo(
                        hint: 'Confirmar contraseña',
                        icono: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verConfirmar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                            color: PaletaColores.textSecondary,
                          ),
                          onPressed: () =>
                            setState(() => _verConfirmar = !_verConfirmar),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        // Verifica que ambas contraseñas sean iguales
                        if (value != _contrasenaController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── BOTÓN REGISTRO ───────────────────────────
                    _botonPrincipal(
                      texto: 'REGISTRARSE',
                      alPresionar: _handleRegistro,
                    ),
                    const SizedBox(height: 12),

                    // ── MENSAJE DE ERROR ─────────────────────────
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

                    // ── ENLACE LOGIN ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(color: PaletaColores.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: PaletaColores.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
      
    );
  }

  // ════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS DE UI
  // ════════════════════════════════════════════════════════

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