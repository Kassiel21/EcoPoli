import 'package:flutter/material.dart';
import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
        .select('id_canje, codigo_seguridad, puntos_usados, estado, fecha_canje')
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

  void _mostrarTicketDetalle(BuildContext context, Map<String, dynamic> canje) {
    final String codigo = canje['codigo_seguridad'] ?? 'ERROR';
    final int puntosTotales = canje['puntos_usados'] ?? 0;
    final String estado = canje['estado'] ?? 'pendiente';
    final DateTime fecha = DateTime.parse(canje['fecha_canje']).toLocal();
    final String fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(fecha);

    Color colorEstado = Colors.orange;
    if (estado == 'confirmado') colorEstado = Colors.green;
    if (estado == 'cancelado' || estado == 'expirado') colorEstado = Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        bool mostrarCodigoManual = false; 

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 40, color: Colors.black87),
                    const SizedBox(height: 12),
                    const Text('TICKET DE CANJE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(fechaFormateada, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    
                    const SizedBox(height: 20),
                    
                    // ── CÓDIGO DE SEGURIDAD Y QR ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Column(
                        children: [
                          Text('CÓDIGO PARA EL BAR', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          
                          QrImageView(
                            data: codigo,
                            version: QrVersions.auto,
                            size: 140.0,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black87),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          //  Si es true muestra el texto, si es false muestra el botón
                          if (mostrarCodigoManual)
                            Column(
                              children: [
                                Text(codigo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4.0, color: Colors.black87)),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    setStateModal(() {
                                      mostrarCodigoManual = false; // Ocultamos el código
                                    });
                                  },
                                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                                  label: const Text('Ocultar código'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade600, // Un color más sutil para ocultar
                                  ),
                                ),
                              ],
                            )
                          else
                            TextButton.icon(
                              onPressed: () {
                                setStateModal(() {
                                  mostrarCodigoManual = true; // Revelamos el código
                                });
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              label: const Text('Mostrar código '),
                              style: TextButton.styleFrom(
                                foregroundColor: PaletaColores.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                backgroundColor: PaletaColores.primary.withValues(alpha: 0.1),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text('- - - - - - - - - - - - - - - - - - - - - - - -', style: TextStyle(color: Colors.grey.shade400), maxLines: 1),
                    const SizedBox(height: 10),

                    FutureBuilder<List<dynamic>>(
                      future: SupabaseConfig.client
                          .from('canje_prod')
                          .select('cantidad, puntos_unitarios, productos(nombre)')
                          .eq('id_canje', canje['id_canje']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator());
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Text('No se pudieron cargar los productos.', style: TextStyle(color: Colors.red));

                        final productos = snapshot.data!;
                        return Column(
                          children: productos.map((prod) {
                            final nombre = prod['productos']['nombre'];
                            final cantidad = prod['cantidad'];
                            final ptsUnitarios = prod['puntos_unitarios'];
                            final subtotal = cantidad * ptsUnitarios;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${cantidad}x $nombre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                  Text('$subtotal puntos', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Text('- - - - - - - - - - - - - - - - - - - - - - - -', style: TextStyle(color: Colors.grey.shade400), maxLines: 1),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL PAGADO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('$puntosTotales puntos', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaletaColores.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cerrar ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Mis canjes', style: TextStyle(fontWeight: FontWeight.bold)),
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

              return GestureDetector(
                onTap: () {
                  // Cuando toquen la tarjeta, se abre el ticket
                  _mostrarTicketDetalle(context, canje);
                },
                child: Container(
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
                      const Text('Nº DE TICKET', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // ID real de la base de datos
                          Text(
                            '#${canje['id_canje'].toString().substring(0, 8).toUpperCase()}',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PaletaColores.textPrimary, letterSpacing: 1.5),
                          ),
                          Text(
                            '-${canje['puntos_usados']} puntos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PaletaColores.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}