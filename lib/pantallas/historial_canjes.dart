import 'package:flutter/material.dart';
import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  
  // Función que va a Supabase y trae solo LOS CANJES DE ESTE USUARIO
  Future<List<Map<String, dynamic>>> _obtenerMisCanjes() async {
    // Gracias al RLS que configuraste en Supabase, esta consulta
    // automáticamente trae solo los datos del usuario logueado.
    final respuesta = await SupabaseConfig.client
        .from('canjes')
        .select('codigo_seguridad, puntos_usados, estado, fecha_canje')
        .order('fecha_canje', ascending: false); // Los más nuevos primero
        
    return List<Map<String, dynamic>>.from(respuesta);
  }

  // Función sencilla para formatear la fecha que viene de la base (Ej: 2026-05-01)
  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaIso.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Mis Códigos de Canje', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.background,
        elevation: 0,
        foregroundColor: PaletaColores.textPrimary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerMisCanjes(),
        builder: (context, snapshot) {
          // 1. Mientras está cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Si hubo un error
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
          }

          final canjes = snapshot.data ?? [];

          // 3. Si no ha comprado nada nunca
          if (canjes.isEmpty) {
            return const Center(
              child: Text('Aún no has generado ningún código.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          // 4. Mostrar la lista de tickets
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: canjes.length,
            itemBuilder: (context, index) {
              final canje = canjes[index];
              final estado = canje['estado'] ?? 'pendiente';
              
              // Colores según el estado
              final esPendiente = estado == 'pendiente';
              final colorEstado = esPendiente ? Colors.orange : PaletaColores.primary;
              final iconoEstado = esPendiente ? Icons.access_time_filled : Icons.check_circle;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatearFecha(canje['fecha_canje']),
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(iconoEstado, size: 14, color: colorEstado),
                              const SizedBox(width: 4),
                              Text(
                                estado.toUpperCase(),
                                style: TextStyle(color: colorEstado, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('CÓDIGO DE RETIRO', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          canje['codigo_seguridad'] ?? 'N/A',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: PaletaColores.textPrimary, letterSpacing: 2.0),
                        ),
                        Text(
                          '-${canje['puntos_usados']} pts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PaletaColores.error),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}