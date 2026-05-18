import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaRecepcionBotellas extends StatefulWidget {
  const PantallaRecepcionBotellas({super.key});

  @override
  State<PantallaRecepcionBotellas> createState() => _PantallaRecepcionBotellasState();
}

class _PantallaRecepcionBotellasState extends State<PantallaRecepcionBotellas> {
  final _supabase = Supabase.instance.client;
  final _correoCtrl = TextEditingController();
  final _botellasCtrl = TextEditingController();
  
  bool _buscando = false;
  bool _guardando = false;
  Map<String, dynamic>? _estudianteEncontrado;

  // 1. BUSCAR ESTUDIANTE
  Future<void> _buscarEstudiante() async {
    if (_correoCtrl.text.trim().isEmpty) return;
    setState(() {
      _buscando = true;
      _estudianteEncontrado = null;
    });

    try {
      final res = await _supabase
          .from('usuarios')
          .select('id_usuario, nombre, apellido, cant_puntos, url_foto, rol')
          .eq('correo', _correoCtrl.text.trim())
          .maybeSingle();

      if (res != null && res['rol'] == 'estudiante') {
        setState(() => _estudianteEncontrado = res);
      } else {
        _mostrarMensaje('No se encontró al estudiante', esError: true);
      }
    } catch (e) {
      _mostrarMensaje('Error al buscar', esError: true);
    } finally {
      setState(() => _buscando = false);
    }
  }

  // REGISTRAR BOTELLAS Y SUMAR PUNTOS
  Future<void> _registrarBotellas() async {
    final cantBotellas = int.tryParse(_botellasCtrl.text.trim()) ?? 0;
    if (cantBotellas <= 0) {
      _mostrarMensaje('Ingresa una cantidad válida', esError: true);
      return;
    }

    setState(() => _guardando = true);

    try {
      final miId = _supabase.auth.currentUser!.id;

      //  Buscar el ID del bar que le pertenece a este Barman
      final datosBar = await _supabase
          .from('bares')
          .select('id_bar')
          .eq('id_usuario', (await _supabase.from('usuarios').select('id_usuario').eq('auth_id', miId).single())['id_usuario'])
          .maybeSingle();

      if (datosBar == null) {
        _mostrarMensaje('No tienes un bar asignado', esError: true);
        setState(() => _guardando = false);
        return;
      }

      //  Calcular Puntos 
      final configPuntos = await _supabase
          .from('configuracion_puntos')
          .select('puntos_por_botella')
          .eq('vigente', true) // Solo trae la configuración activa
          .order('fecha_inicio', ascending: false)
          .limit(1)
          .maybeSingle();

      // Si por alguna razón no hay configuración en la base de datos, usamos 1 por defecto para que no colapse
      final multiplicador = configPuntos != null ? (configPuntos['puntos_por_botella'] as int) : 1; 
      
      final puntosAsignados = cantBotellas * multiplicador; 
      final idEstudiante = _estudianteEncontrado!['id_usuario'];
      final puntosActuales = _estudianteEncontrado!['cant_puntos'];

      // Insertar en Entregas
      final idBarman = (await _supabase.from('usuarios').select('id_usuario').eq('auth_id', miId).single())['id_usuario'];

      final nuevaEntrega = await _supabase.from('entregas').insert({
        'id_usuario': idEstudiante,
        'id_bar': datosBar['id_bar'],
        'cantidad_botellas': cantBotellas,
        'puntos_asignados': puntosAsignados,
        'estado': 'validada',
        'registrado_por': idBarman 
      }).select('id_entrega').single();

      // Sumar puntos al estudiante
      final nuevosPuntos = puntosActuales + puntosAsignados;
      await _supabase.from('usuarios').update({
        'cant_puntos': puntosActuales + puntosAsignados
      }).eq('id_usuario', idEstudiante);

      //  RECIBO PARA MI IMPACTO
      await _supabase.from('historial_puntos').insert({
        'id_usuario': idEstudiante,
        'id_entrega': nuevaEntrega['id_entrega'],
        'puntos': puntosAsignados, 
        'descripcion': 'Reciclaje de $cantBotellas botellas',
        'saldo_post': nuevosPuntos
      });

      // Éxito
      _mostrarMensaje('¡Se añadieron $puntosAsignados puntos al estudiante!', esError: false);
      
      // Limpiar pantalla
      setState(() {
        _estudianteEncontrado = null;
        _correoCtrl.clear();
        _botellasCtrl.clear();
      });

    } catch (e) {
      debugPrint(e.toString());
      _mostrarMensaje('Error al registrar la entrega', esError: true);
    } finally {
      setState(() => _guardando = false);
    }
  }

  // ── FUNCIÓN PARA ENVIAR EL REPORTE ──
  Future<void> _enviarReporte(String motivo) async {
    try {
      final miAuthId = _supabase.auth.currentUser!.id;
      final datosBarman = await _supabase.from('usuarios').select('id_usuario').eq('auth_id', miAuthId).single();
      
      await _supabase.from('reportes_usuarios').insert({
        'id_estudiante': _estudianteEncontrado!['id_usuario'],
        'id_admin_bar': datosBarman['id_usuario'],
        'motivo': motivo
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Estudiante reportado. El sistema evaluará su estado.'), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      debugPrint('Error al reportar: $e');
      _mostrarMensaje('Error al enviar el reporte', esError: true);
    }
  }

  // ── VENTANA FLOTANTE PARA CAPTURAR EL MOTIVO ──
  void _mostrarDialogoReporte() {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Reportar Estudiante')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Por qué estás reportando a este usuario?', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: InputDecoration(hintText: ' ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () {
              if (motivoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _enviarReporte(motivoCtrl.text.trim());
            },
            child: const Text('Enviar Reporte'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String msg, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: esError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Recibir Botellas'),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buscar Estudiante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _correoCtrl,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@gmail.com',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _buscando ? null : _buscarEstudiante,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaletaColores.primary,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _buscando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                )
              ],
            ),
            
            const SizedBox(height: 32),

            if (_estudianteEncontrado != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: PaletaColores.primary.withValues(alpha: 0.1),
                      backgroundImage: _estudianteEncontrado!['url_foto'] != null ? NetworkImage(_estudianteEncontrado!['url_foto']) : null,
                      child: _estudianteEncontrado!['url_foto'] == null ? const Icon(Icons.person, size: 30, color: Colors.green) : null,
                    ),
                    const SizedBox(height: 12),
                    Text('${_estudianteEncontrado!['nombre']} ${_estudianteEncontrado!['apellido']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Saldo actual: ${_estudianteEncontrado!['cant_puntos']} puntos', style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 32),
                    TextField(
                      controller: _botellasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de botellas recibidas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.recycling, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // BOTONES 
                    Row(
                      children: [
                        // Botón de Reportar
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: _guardando ? null : _mostrarDialogoReporte,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade300),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: const Icon(Icons.flag_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de Recibir
                        Expanded(
                          flex: 5,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _registrarBotellas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _guardando 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Asignar Puntos', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                    
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}