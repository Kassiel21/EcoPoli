import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PantallaRevisionSolicitudes extends StatefulWidget {
  const PantallaRevisionSolicitudes({super.key});

  @override
  State<PantallaRevisionSolicitudes> createState() => _PantallaRevisionSolicitudesState();
}

class _PantallaRevisionSolicitudesState extends State<PantallaRevisionSolicitudes> {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = true;
  List<Map<String, dynamic>> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _estaCargando = true);
    try {
      debugPrint('🔍 Buscando solicitudes pendientes...');
      
      final datos = await _supabase
          .from('solicitudes_bar')
          .select('*, usuarios!solicitudes_bar_id_usuario_fkey(nombre, apellido)') 
          .eq('estado', 'pendiente');

      debugPrint('✅ Solicitudes encontradas: $datos'); 

      if (mounted) {
        setState(() {
          _solicitudes = List<Map<String, dynamic>>.from(datos);
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 Error crítico cargando solicitudes: $e');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  // ── FUNCIÓN PARA ABRIR EL PDF/IMAGEN ──
  Future<void> _verDocumento(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este usuario no adjuntó un documento')));
      return;
    }
    
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      debugPrint('Error abriendo url: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir el documento.')));
    }
  }

  // ── FUNCIÓN PARA APROBAR CON COORDENADAS CORREGIDAS ──
  Future<void> _aprobarSolicitud(Map<String, dynamic> solicitud) async {
    try {
      final idUsuario = solicitud['id_usuario'];
      final textoCrudo = solicitud['nombre_bar']?.toString().trim() ?? '';
      final nombreBar = textoCrudo.isEmpty ? 'Bar Universitario' : textoCrudo;
      final descripcion = solicitud['descripcion'] ?? 'Sin descripción'; 
      
      // 👇 SOLUCIÓN AL ERROR: Extraemos las coordenadas que el estudiante mandó en su solicitud
      final latitud = solicitud['latitud'] ?? 0.0;
      final longitud = solicitud['longitud'] ?? 0.0;

      // 1. Actualizar el estado de la solicitud
      await _supabase
          .from('solicitudes_bar')
          .update({'estado': 'aprobada', 'fecha_revision': DateTime.now().toIso8601String()})
          .eq('id_solicitud', solicitud['id_solicitud']);

      // 2. Cambiar el rol del usuario a 'admin_bar'
      await _supabase
          .from('usuarios')
          .update({'rol': 'admin_bar'})
          .eq('id_usuario', idUsuario);

      // 3. Crear el bar automáticamente mandando TODOS los campos obligatorios
      await _supabase
          .from('bares')
          .insert({
            'id_usuario': idUsuario,
            'nombre': nombreBar,
            'descripcion': descripcion,
            'latitud': latitud,    // ✅ Pasamos la latitud real
            'longitud': longitud,  // ✅ Pasamos la longitud real
            'estado_bar': true
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Solicitud aprobada y Bar registrado con éxito'), backgroundColor: Colors.green)
        );
        _cargarSolicitudes(); // Recargar lista automáticamente
      }
    } on PostgrestException catch (errorBD) {
      debugPrint('🚨 Error de Postgres: ${errorBD.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error BD: ${errorBD.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint('Error general: $e');
    }
  }

  // ── NUEVO: FUNCIÓN PARA RECHAZAR SOLICITUD ──
  Future<void> _rechazarSolicitud(Map<String, dynamic> solicitud, String motivo) async {
    try {
      await _supabase
          .from('solicitudes_bar')
          .update({
            'estado': 'rechazada',
            'fecha_revision': DateTime.now().toIso8601String(),
            'razon_rechazo': motivo // Guarda el por qué se negó la solicitud
          })
          .eq('id_solicitud', solicitud['id_solicitud']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Solicitud rechazada correctamente'), backgroundColor: Colors.orange)
        );
        _cargarSolicitudes(); // Refrescar la UI
      }
    } catch (e) {
      debugPrint('Error al rechazar: $e');
    }
  }

  // ── NUEVO: VENTANA FLOTANTE PARA CAPTURAR EL MOTIVO ──
  void _mostrarDialogoRechazo(Map<String, dynamic> solicitud) {
    final motivoCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechazar Solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Especifica la razón del rechazo:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: El documento de permiso está expirado...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () {
              if (motivoCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un motivo')));
                return;
              }
              Navigator.pop(ctx); // Cerrar ventana
              _rechazarSolicitud(solicitud, motivoCtrl.text.trim());
            },
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Revisión de Solicitudes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
              ? _vistaVacia()
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudes,
                  color: PaletaColores.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) => _tarjetaSolicitud(_solicitudes[index]),
                  ),
                ),
    );
  }

  Widget _vistaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all, size: 80, color: PaletaColores.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No hay solicitudes pendientes', style: TextStyle(color: PaletaColores.textSecondary)),
        ],
      ),
    );
  }

  Widget _tarjetaSolicitud(Map<String, dynamic> solicitud) {
    try {
      final nombreBar = solicitud['nombre_bar']?.toString() ?? 'Sin nombre';
      final descripcion = solicitud['descripcion']?.toString() ?? 'Sin descripción';
      final referencia = solicitud['referencia']?.toString() ?? 'No especificada';
      final urlPermiso = solicitud['documento_url']?.toString(); 
      
      final datosUsuario = solicitud['usuarios'] ?? {};
      final nombreUsuario = datosUsuario['nombre']?.toString() ?? 'Usuario';
      final apellidoUsuario = datosUsuario['apellido']?.toString() ?? 'Desconocido';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: PaletaColores.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.store, color: PaletaColores.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombreBar, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Solicitado por: $nombreUsuario $apellidoUsuario', style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(descripcion, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text('📍 Ref: $referencia', style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            
            // ── FILA 1: VER PERMISO (ANCHO COMPLETO) ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _verDocumento(urlPermiso),
                icon: Icon(urlPermiso != null ? Icons.description_outlined : Icons.cancel_outlined, size: 18),
                label: Text(urlPermiso != null ? 'Ver Permiso Adjunto' : 'Sin Archivo', style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: urlPermiso != null ? PaletaColores.primary : Colors.grey,
                  side: BorderSide(color: urlPermiso != null ? PaletaColores.primary : Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // ── FILA 2: ACCIONES (RECHAZAR | APROBAR) ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoRechazo(solicitud),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobarSolicitud(solicitud),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.withValues(alpha:0.1),
        child: Text('Error pintando tarjeta: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }
}