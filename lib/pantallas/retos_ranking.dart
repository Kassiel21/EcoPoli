import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaRetos extends StatefulWidget {
  const PantallaRetos({super.key});

  @override
  State<PantallaRetos> createState() => _PantallaRetosState();
}

class _PantallaRetosState extends State<PantallaRetos> {
  final _supabase = Supabase.instance.client;

  // ── CONSULTA A BASE DE DATOS PARA EL RANKING ───────────────────
  Future<List<Map<String, dynamic>>> _obtenerRanking() async {
    final respuesta = await _supabase
        .from('usuarios')
        .select('id_usuario, nombre, apellido, cant_puntos, auth_id')
        .eq('rol', 'estudiante') // ¡Importante! Solo compiten estudiantes
        .order('cant_puntos', ascending: false) // Mayor puntaje primero
        .limit(20); // Top 20 de la universidad
        
    return List<Map<String, dynamic>>.from(respuesta);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: PaletaColores.background,
        appBar: AppBar(
          title: const Text('Zona EcoPoli 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: PaletaColores.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'Misiones', icon: Icon(Icons.task_alt)),
              Tab(text: 'Ranking', icon: Icon(Icons.leaderboard_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _construirMisiones(),
            _construirRanking(),
          ],
        ),
      ),
    );
  }

  // ──  VISTA DE MISIONES 
  Widget _construirMisiones() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '¡Completa retos semanales generados por IA para ganar puntos extra!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Conectando con la IA...', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──  VISTA DE RANKING 
  Widget _construirRanking() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _obtenerRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar el ranking.'));
        }

        final usuarios = snapshot.data ?? [];
        if (usuarios.isEmpty) {
          return const Center(child: Text('Aún no hay estudiantes con puntos.'));
        }

        // Separamos el Top 3 del resto de la lista
        final top3 = usuarios.take(3).toList();
        final resto = usuarios.skip(3).toList();

        return Column(
          children: [
            // ── EL PODIO (TOP 3) ──
            Container(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              decoration: BoxDecoration(
                color: PaletaColores.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2do Lugar (Plata)
                  if (top3.length > 1) 
                    _construirPilarPodio(top3[1], 2, 110, Colors.grey.shade300),
                  const SizedBox(width: 10),
                  // 1er Lugar (Oro)
                  if (top3.isNotEmpty) 
                    _construirPilarPodio(top3[0], 1, 150, Colors.amber),
                  const SizedBox(width: 10),
                  // 3er Lugar (Bronce)
                  if (top3.length > 2) 
                    _construirPilarPodio(top3[2], 3, 85, const Color(0xFFCD7F32)),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // ── EL RESTO DE LA LISTA (4to en adelante) ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: resto.length,
                itemBuilder: (context, index) {
                  final usuario = resto[index];
                  final posicion = index + 4; // Porque ya mostramos 3 arriba
                  
                  // Verificamos si es el usuario actual para resaltarlo
                  final esMiUsuario = usuario['auth_id'] == _supabase.auth.currentUser?.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: esMiUsuario ? PaletaColores.primary.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: esMiUsuario ? Border.all(color: PaletaColores.primary.withValues(alpha: 0.5)) : null,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#$posicion',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          backgroundColor: PaletaColores.primary.withValues(alpha: 0.2),
                          child: Text(
                            usuario['nombre'][0].toUpperCase(),
                            style: TextStyle(color: PaletaColores.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '${usuario['nombre']} ${usuario['apellido']}',
                            style: TextStyle(
                              fontWeight: esMiUsuario ? FontWeight.w900 : FontWeight.bold, 
                              fontSize: 15,
                              color: PaletaColores.textPrimary
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${usuario['cant_puntos']} puntos',
                          style: TextStyle(fontWeight: FontWeight.w900, color: PaletaColores.primary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // COLUMNAS DEL PODIO 
  Widget _construirPilarPodio(Map<String, dynamic> usuario, int posicion, double altura, Color colorPilar) {
    final esMiUsuario = usuario['auth_id'] == _supabase.auth.currentUser?.id;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Nombre del estudiante 
        Text(
          usuario['nombre'].toString().split(' ')[0], 
          style: TextStyle(
            color: PaletaColores.textPrimary, 
            fontWeight: esMiUsuario ? FontWeight.w900 : FontWeight.bold, 
            fontSize: 14
          ),
        ),
        const SizedBox(height: 6),
        // Burbuja de Puntos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: PaletaColores.primary.withValues(alpha: 0.15), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Text(
            '${usuario['cant_puntos']} puntos', 
            style: TextStyle(color: PaletaColores.primary, fontSize: 11, fontWeight: FontWeight.w900)
          ),
        ),
        const SizedBox(height: 10),
        // Pilar de color con sombra brillante
        Container(
          width: 85,
          height: altura,
          decoration: BoxDecoration(
            color: colorPilar,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: colorPilar.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, -4))
            ]
          ),
          child: Center(
            child: Text(
              '$posicion',
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}