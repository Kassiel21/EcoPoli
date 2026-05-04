import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaCambiarFoto extends StatefulWidget {
  const PantallaCambiarFoto({super.key});

  @override
  State<PantallaCambiarFoto> createState() => _PantallaCambiarFotoState();
}

class _PantallaCambiarFotoState extends State<PantallaCambiarFoto> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Foto de Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── FOTO ACTUAL ───────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 72,
                    backgroundColor: PaletaColores.fieldBackground,
                    child: Icon(Icons.person, size: 72, color: PaletaColores.primary.withValues(alpha: 0.5)),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PaletaColores.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── OPCIONES ──────────────────────────────────
            _opcionFoto(
              icono: Icons.photo_camera_outlined,
              titulo: 'Tomar foto',
              subtitulo: 'Usa la cámara de tu dispositivo',
              onTap: () => _seleccionarFuente('camara'),
            ),
            const SizedBox(height: 12),
            _opcionFoto(
              icono: Icons.photo_library_outlined,
              titulo: 'Elegir de galería',
              subtitulo: 'Selecciona una imagen guardada',
              onTap: () => _seleccionarFuente('galeria'),
            ),
            const SizedBox(height: 12),
            _opcionFoto(
              icono: Icons.delete_outline,
              titulo: 'Eliminar foto',
              subtitulo: 'Volver a la imagen predeterminada',
              color: PaletaColores.error,
              onTap: () => _eliminarFoto(),
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
    );
  }

  Widget _opcionFoto({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? PaletaColores.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: c, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
                  Text(subtitulo, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: PaletaColores.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _seleccionarFuente(String fuente) {
    // TODO: integrar image_picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seleccionando desde $fuente...'), backgroundColor: PaletaColores.primary),
    );
  }

  void _eliminarFoto() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Deseas eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Eliminar', style: TextStyle(color: PaletaColores.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Foto actualizada'), backgroundColor: PaletaColores.primary),
      );
      Navigator.pop(context);
    }
  }
}
