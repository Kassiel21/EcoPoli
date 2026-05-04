import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaCambioRol extends StatefulWidget {
  const PantallaCambioRol({super.key});

  @override
  State<PantallaCambioRol> createState() => _PantallaCambioRolState();
}

class _PantallaCambioRolState extends State<PantallaCambioRol> {
  final _correoController = TextEditingController();
  final _rolController = TextEditingController();
  String? _rolSeleccionado;
  bool _cargando = false;

  final List<String> _roles = ['Estudiante', 'Encargado de Bar', 'Administrador'];

  @override
  void dispose() {
    _correoController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Cambio de Rol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DESCRIPCIÓN ───────────────────────────────
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
                      'Asigna un nuevo rol a un usuario registrado en la plataforma.',
                      style: TextStyle(fontSize: 13, color: PaletaColores.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── CAMPO CORREO ──────────────────────────────
            Text('Correo del usuario', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoracion('correo@ejemplo.com', Icons.email_outlined),
            ),
            const SizedBox(height: 20),

            // ── SELECTOR DE ROL ───────────────────────────
            Text('Nuevo rol', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: PaletaColores.fieldBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rolSeleccionado,
                  hint: Text('Seleccionar rol', style: TextStyle(color: PaletaColores.textSecondary)),
                  isExpanded: true,
                  items: _roles.map((rol) => DropdownMenuItem(value: rol, child: Text(rol))).toList(),
                  onChanged: (v) => setState(() => _rolSeleccionado = v),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── BOTÓN CONFIRMAR ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _confirmarCambio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _cargando
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Confirmar Cambio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracion(String hint, IconData icono) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: PaletaColores.textSecondary, fontSize: 14),
      prefixIcon: Icon(icono, color: PaletaColores.primary),
      filled: true,
      fillColor: PaletaColores.fieldBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _confirmarCambio() async {
    if (_correoController.text.isEmpty || _rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }
    setState(() => _cargando = true);
    await Future.delayed(const Duration(seconds: 1)); // Simula llamada a API
    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol cambiado a "$_rolSeleccionado" correctamente'),
          backgroundColor: PaletaColores.primary,
        ),
      );
    }
  }
}
