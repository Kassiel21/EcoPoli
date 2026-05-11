import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final correo = _correoController.text.trim();
    if (correo.isEmpty || _rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
      return;
    }
    
    setState(() => _cargando = true);
    
    // Traducir el nombre del rol visual al enum de la base de datos
    String rolBD = 'estudiante';
    if (_rolSeleccionado == 'Encargado de Bar') rolBD = 'admin_bar';
    if (_rolSeleccionado == 'Administrador') rolBD = 'super_admin';

    try {
      final supabase = Supabase.instance.client;
      
      //  Buscamos al usuario por su correo
      final userResponse = await supabase.from('usuarios').select('id_usuario').eq('correo', correo).maybeSingle();
      
      if (userResponse == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No existe un usuario con ese correo'), backgroundColor: Colors.red));
        setState(() => _cargando = false);
        return;
      }

      //  Actualizamos el rol en la base de datos
      await supabase.from('usuarios').update({'rol': rolBD}).eq('id_usuario', userResponse['id_usuario']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol cambiado a "$_rolSeleccionado" correctamente'), backgroundColor: Colors.green),
        );
        // ESTO ES LO QUE RECARGA EL PERFIL AL INSTANTE
        Navigator.pop(context, true); 
      }
    } catch (e) {
      debugPrint('Error al cambiar rol: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar el rol'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}
