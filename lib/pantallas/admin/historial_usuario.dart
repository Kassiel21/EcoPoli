import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PantallaHistorialUsuarioAdmin extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PantallaHistorialUsuarioAdmin({super.key, required this.usuario});

  @override
  State<PantallaHistorialUsuarioAdmin> createState() => _PantallaHistorialUsuarioAdminState();
}

class _PantallaHistorialUsuarioAdminState extends State<PantallaHistorialUsuarioAdmin> {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = true;
  List<Map<String, dynamic>> _actividad = [];
  int _puntosActuales = 0;

  @override
  void initState() {
    super.initState();
    _puntosActuales = widget.usuario['cant_puntos'] ?? 0;
    _cargarActividad();
  }

  Future<void> _cargarActividad() async {
    setState(() => _estaCargando = true);
    try {
      // Traemos Entregas y Canjes en paralelo
      final idUser = widget.usuario['id_usuario'];
      final datosUser = await _supabase
          .from('usuarios')
          .select('cant_puntos')
          .eq('id_usuario', idUser)
          .single();
      
      final entregas = await _supabase.from('entregas').select('*, bares(nombre)').eq('id_usuario', idUser);
      final canjes = await _supabase.from('canjes').select('*, bares(nombre)').eq('id_usuario', idUser);

      // Unificamos y marcamos tipo para la lista
      List<Map<String, dynamic>> temporal = [];
      for (var e in entregas) {
        temporal.add({...e, 'tipo_act': 'entrega', 'fecha_sort': e['fecha_entrega']});
      }
      for (var c in canjes) {
        temporal.add({...c, 'tipo_act': 'canje', 'fecha_sort': c['fecha_canje']});
      }

      // Ordenar por fecha más reciente
      temporal.sort((a, b) => DateTime.parse(b['fecha_sort']).compareTo(DateTime.parse(a['fecha_sort'])));

      if (mounted) {
        setState(() {
          _puntosActuales = datosUser['cant_puntos'] ?? 0;
          _actividad = temporal;
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error historial: $e');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: Text('Actividad de ${widget.usuario['nombre']}', style: const TextStyle(fontSize: 18)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarActividad,
        color: PaletaColores.primary,
        child: Column(
          children: [
            _tarjetaResumen(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(alignment: Alignment.centerLeft, child: Text('Movimientos Recientes', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: _estaCargando 
                ? const Center(child: CircularProgressIndicator())
                : _actividad.isEmpty 
                  ? const Center(child: Text('Sin movimientos registrados'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _actividad.length,
                      itemBuilder: (context, index) => _itemActividad(_actividad[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: PaletaColores.primary, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(
        children: [
          Text('$_puntosActuales', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('PUNTOS DISPONIBLES', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _itemActividad(Map<String, dynamic> item) {
    bool esEntrega = item['tipo_act'] == 'entrega';
    final fecha = DateTime.parse(item['fecha_sort']).toLocal();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: esEntrega ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(esEntrega ? Icons.add_circle_outline : Icons.remove_circle_outline, color: esEntrega ? Colors.green : Colors.red),
        ),
        title: Text(esEntrega ? 'Reciclaje: ${item['cantidad_botellas']} botellas' : 'Canje de productos'),
        subtitle: Text('En: ${item['bares']['nombre']} • ${DateFormat('dd/MM/yy HH:mm').format(fecha)}'),
        trailing: Text(
          esEntrega ? '+${item['puntos_asignados']}' : '-${item['puntos_usados']}',
          style: TextStyle(fontWeight: FontWeight.bold, color: esEntrega ? Colors.green : Colors.red, fontSize: 16),
        ),
      ),
    );
  }
}