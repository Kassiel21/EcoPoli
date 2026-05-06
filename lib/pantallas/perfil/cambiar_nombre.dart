import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/repositorios/perfil_repositorio.dart';
import 'package:eco_poli/widgets/perfil/campo_texto_widget.dart';

/// Pantalla que permite al usuario cambiar su nombre visible en la app.
/// Carga el nombre actual desde Supabase y guarda el nuevo al confirmar.
class PantallaCambiarNombre extends StatefulWidget {
  const PantallaCambiarNombre({super.key});

  @override
  State<PantallaCambiarNombre> createState() => _PantallaCambiarNombreState();
}

class _PantallaCambiarNombreState extends State<PantallaCambiarNombre> {
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Repositorio de perfil: toda la lógica de datos está aquí
  final _repositorio = PerfilRepositorio();

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreActual();
  }

  /// Carga el nombre actual del usuario desde Supabase al abrir la pantalla
  Future<void> _cargarNombreActual() async {
    try {
      final perfil = await _repositorio.obtenerPerfil();
      if (mounted) _nombreController.text = perfil.nombre;
    } catch (e) {
      debugPrint('❌ Error cargando nombre: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Cambiar Nombre',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── AVISO INFORMATIVO ──────────────────────────────────────────
              _bannerInfo('Este nombre será visible para otros usuarios en la aplicación.'),
              const SizedBox(height: 28),

              // ── CAMPO NOMBRE ───────────────────────────────────────────────
              Text(
                'Nuevo nombre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PaletaColores.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CampoTextoWidget(
                controller: _nombreController,
                hint: 'Ingresa tu nombre',
                icono: Icons.person_outline,
                capitalizacion: TextCapitalization.words,
                validador: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa un nombre';
                  if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── BOTÓN GUARDAR ──────────────────────────────────────────────
              _botonGuardar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS PRIVADOS ────────────────────────────────────────────────────────

  Widget _bannerInfo(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletaColores.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletaColores.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: PaletaColores.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(fontSize: 13, color: PaletaColores.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletaColores.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _cargando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ── LÓGICA ──────────────────────────────────────────────────────────────────

  /// Valida el formulario y guarda el nuevo nombre en Supabase
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await _repositorio.actualizarNombre(_nombreController.text);

    setState(() => _cargando = false);

    if (!mounted) return;

    if (error != null) {
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: PaletaColores.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nombre actualizado correctamente'),
          backgroundColor: PaletaColores.primary,
        ),
      );
      Navigator.pop(context);
    }
  }
}
