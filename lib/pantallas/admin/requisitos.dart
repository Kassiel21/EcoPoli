import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaRequisitos extends StatelessWidget {
  const PantallaRequisitos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Requisitos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DESCRIPCIÓN ───────────────────────────────
            Text(
              'Para activar tu Perfil de Bar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Para activar tu Perfil de Bar, es obligatorio adjuntar los permisos otorgados por la ESPOCH. '
              'Una vez validada tu documentación por el equipo técnico, se habilitarán tus funciones de administrador.',
              style: TextStyle(fontSize: 14, color: PaletaColores.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),

            // ── LISTA DE REQUISITOS ───────────────────────
            _itemRequisito(Icons.description_outlined, 'Permiso ESPOCH', 'Documento oficial emitido por la institución'),
            const SizedBox(height: 12),
            _itemRequisito(Icons.badge_outlined, 'Identificación', 'Cédula o carnet institucional vigente'),
            const SizedBox(height: 12),
            _itemRequisito(Icons.store_outlined, 'Datos del Bar', 'Nombre, ubicación y horario de atención'),
            const SizedBox(height: 32),

            // ── BOTÓN SUBIR DOCUMENTOS ────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir Documentos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── IMAGEN DECORATIVA ─────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                color: PaletaColores.fieldBackground,
                child: Icon(Icons.store, size: 80, color: PaletaColores.primary.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRequisito(IconData icono, String titulo, String descripcion) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaColores.fieldBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PaletaColores.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: PaletaColores.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(descripcion, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: PaletaColores.primary),
        ],
      ),
    );
  }
}
