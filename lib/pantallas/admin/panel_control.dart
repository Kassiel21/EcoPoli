import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/pantallas/admin/gestion_estudiantes.dart';
import 'package:eco_poli/pantallas/admin/gestion_bares.dart';

class PantallaPanelControl extends StatelessWidget {
  const PantallaPanelControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: Column(
        children: [
          _encabezado(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── MÉTRICAS ──────────────────────────────
                  Text(
                    'Resumen General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: PaletaColores.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _tarjetaMetrica('Total\nEstudiantes', '120', Icons.people_outline, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _tarjetaMetrica('Total\nBares', '8', Icons.store_outlined, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── ACCIONES ──────────────────────────────
                  Text(
                    'Gestión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: PaletaColores.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _itemAccion(
                    context,
                    icono: Icons.people,
                    titulo: 'Gestión de Estudiantes',
                    subtitulo: 'Administrar usuarios registrados',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaGestionEstudiantes())),
                  ),
                  const SizedBox(height: 10),
                  _itemAccion(
                    context,
                    icono: Icons.store,
                    titulo: 'Gestión de Bares',
                    subtitulo: 'Administrar bares y encargados',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaGestionBares())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezado(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PaletaColores.primary, const Color(0xFF3B6D11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Volver',
              ),
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel de Control', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Desarrollador', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaMetrica(String etiqueta, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(etiqueta, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
        ],
      ),
    );
  }

  Widget _itemAccion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletaColores.fieldBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PaletaColores.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: PaletaColores.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
                  Text(subtitulo, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: PaletaColores.textSecondary),
          ],
        ),
      ),
    );
  }
}
