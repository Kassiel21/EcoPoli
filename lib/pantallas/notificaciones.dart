import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  // Datos de prueba (Dummy data). En el futuro, esto vendrá de Supabase.
  final List<Map<String, dynamic>> _notificaciones = [
    {
      'titulo': '¡Puntos recibidos!',
      'mensaje': 'Acabas de recibir 50 puntos por entregar botellas de plástico en los bares de la ESPOCH.',
      'icono': Icons.recycling,
      'color': Colors.green,
      'tiempo': 'Hace 2 horas',
      'leida': false, // Al ser false, se pintará un poco más resaltada
    },
    {
      'titulo': 'Canje exitoso',
      'mensaje': 'Tu código de canje fue validado correctamente. ¡Disfruta tu recompensa!',
      'icono': Icons.check_circle,
      'color': Colors.teal,
      'tiempo': 'Ayer',
      'leida': true,
    },
    {
      'titulo': 'Nuevo beneficio',
      'mensaje': 'Han llegado libretas ecológicas al catálogo de EcoPoli. ¡Ve a revisarlas!',
      'icono': Icons.new_releases,
      'color': Colors.orange,
      'tiempo': 'Hace 3 días',
      'leida': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.background,
        elevation: 0,
        foregroundColor: PaletaColores.textPrimary,
      ),
      body: _notificaciones.isEmpty
          ? const Center(child: Text('No tienes notificaciones nuevas.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _notificaciones.length,
              itemBuilder: (context, index) {
                final noti = _notificaciones[index];
                final bool esLeida = noti['leida'];

                return Dismissible(
                  // Necesita una llave única para saber cuál borrar
                  key: Key(noti['titulo'] + index.toString()),
                  direction: DismissDirection.endToStart, // Deslizar de derecha a izquierda
                  
                  // El fondo rojo que aparece debajo al deslizar
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  ),
                  
                  // Lo que pasa cuando terminas de deslizar
                  onDismissed: (direction) {
                    setState(() {
                      _notificaciones.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación eliminada'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  
                  // 👇 NUEVO: GestureDetector para marcar como leída
                  child: GestureDetector(
                    onTap: () {
                      if (!esLeida) {
                        setState(() {
                          _notificaciones[index]['leida'] = true;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: esLeida ? Colors.white : PaletaColores.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: esLeida 
                            ? Border.all(color: Colors.grey.shade200) 
                            : Border.all(color: PaletaColores.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: noti['color'].withValues(alpha: 0.1),
                            child: Icon(noti['icono'], color: noti['color']),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        noti['titulo'],
                                        style: TextStyle(
                                          fontWeight: esLeida ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 16,
                                          color: PaletaColores.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!esLeida)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(color: PaletaColores.primary, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  noti['mensaje'],
                                  style: TextStyle(
                                    color: esLeida ? PaletaColores.textSecondary : PaletaColores.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  noti['tiempo'],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}