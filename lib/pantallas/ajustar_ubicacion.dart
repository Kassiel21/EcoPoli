import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaAjustarUbicacion extends StatefulWidget {
  const PantallaAjustarUbicacion({super.key});

  @override
  State<PantallaAjustarUbicacion> createState() => _PantallaAjustarUbicacionState();
}

class _PantallaAjustarUbicacionState extends State<PantallaAjustarUbicacion> {
  final _ciudadController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _cargando = false;
  bool _usarUbicacionActual = false;

  @override
  void dispose() {
    _ciudadController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Ajustar Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── MAPA PLACEHOLDER ──────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                color: PaletaColores.fieldBackground,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 80, color: PaletaColores.primary.withValues(alpha: 0.25)),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: PaletaColores.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Ver mapa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── USAR UBICACIÓN ACTUAL ─────────────────────
            Container(
              decoration: BoxDecoration(
                color: PaletaColores.fieldBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                value: _usarUbicacionActual,
                onChanged: (v) {
                  setState(() => _usarUbicacionActual = v);
                  if (v) _obtenerUbicacionActual();
                },
                activeColor: PaletaColores.primary,
                title: const Text('Usar mi ubicación actual', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Detectar automáticamente', style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                secondary: Icon(Icons.gps_fixed, color: PaletaColores.primary),
              ),
            ),
            const SizedBox(height: 20),

            // ── CAMPOS MANUALES ───────────────────────────
            Text('O ingresa manualmente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
            const SizedBox(height: 12),

            _campo(_ciudadController, 'Ciudad', Icons.location_city_outlined),
            const SizedBox(height: 12),
            _campo(_direccionController, 'Dirección o sector', Icons.place_outlined),
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
                    : const Text('Guardar ubicación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController controller, String hint, IconData icono) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: PaletaColores.textSecondary, fontSize: 14),
        prefixIcon: Icon(icono, color: PaletaColores.primary),
        filled: true,
        fillColor: PaletaColores.fieldBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletaColores.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _obtenerUbicacionActual() {
    // TODO: integrar geolocator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Obteniendo ubicación...'), backgroundColor: PaletaColores.primary),
    );
  }

  Future<void> _guardar() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: guardar en Supabase
    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Ubicación guardada correctamente'), backgroundColor: PaletaColores.primary),
      );
      Navigator.pop(context);
    }
  }
}
