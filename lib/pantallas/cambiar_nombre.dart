import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/servicios/autenticacion.dart';

class PantallaCambiarNombre extends StatefulWidget {
  const PantallaCambiarNombre({super.key});

  @override
  State<PantallaCambiarNombre> createState() => _PantallaCambiarNombreState();
}

class _PantallaCambiarNombreState extends State<PantallaCambiarNombre> {
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _servicioAuth = Autenticacion();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreActual();
  }

  Future<void> _cargarNombreActual() async {
    final nombre = await _servicioAuth.obtenerNombreUsuario();
    _nombreController.text = nombre;
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
        title: const Text('Cambiar Nombre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

              // ── INFO ──────────────────────────────────────
              Container(
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
                        'Este nombre será visible para otros usuarios en la aplicación.',
                        style: TextStyle(fontSize: 13, color: PaletaColores.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── CAMPO NOMBRE ──────────────────────────────
              Text('Nuevo nombre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Ingresa tu nombre',
                  hintStyle: TextStyle(color: PaletaColores.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.person_outline, color: PaletaColores.primary),
                  filled: true,
                  fillColor: PaletaColores.fieldBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PaletaColores.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa un nombre';
                  if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── BOTÓN GUARDAR ─────────────────────────────
              SizedBox(
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
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: llamada a Supabase
    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Nombre actualizado correctamente'), backgroundColor: PaletaColores.primary),
      );
      Navigator.pop(context);
    }
  }
}
