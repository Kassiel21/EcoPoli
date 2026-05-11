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
      // Mode InAppBrowserView fuerza al sistema a abrir una ventanita de navegador dentro de la app
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      debugPrint('Error abriendo url: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir el documento. Verifica el formato de la URL.')));
    }
  }

  // ── FUNCIÓN PARA APROBAR ──
  Future<void> _aprobarSolicitud(Map<String, dynamic> solicitud) async {
    try {
      // 1. Actualizar el estado de la solicitud
      await _supabase
          .from('solicitudes_bar')
          .update({'estado': 'aprobada', 'fecha_revision': DateTime.now().toIso8601String()})
          .eq('id_solicitud', solicitud['id_solicitud']);

      // 2. Cambiar el rol del usuario a 'admin_bar'
      await _supabase
          .from('usuarios')
          .update({'rol': 'admin_bar'})
          .eq('id_usuario', solicitud['id_usuario']);

      // 3. (Opcional) Aquí podrías insertar automáticamente en la tabla 'bares'
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud aprobada con éxito'), backgroundColor: Colors.green)
        );
        _cargarSolicitudes(); // Recargar lista
      }
    } catch (e) {
      debugPrint('Error al aprobar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Revision de Solicitudes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];
                      return _tarjetaSolicitud(solicitud);
                    },
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
      // 1. Variables blindadas contra nulos
      final nombreBar = solicitud['nombre_bar']?.toString() ?? 'Sin nombre';
      final descripcion = solicitud['descripcion']?.toString() ?? 'Sin descripción';
      final referencia = solicitud['referencia']?.toString() ?? 'No especificada';
      final urlPermiso = solicitud['imagen_url']?.toString();
      
      // 2. Extracción segura del usuario (Considerando el alias de la llave foránea)
      final datosUsuario = solicitud['usuarios'] ?? solicitud['usuarios!solicitudes_bar_id_usuario_fkey'] ?? {};
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
                      // 👇 AQUÍ USAMOS LAS VARIABLES SEGURAS
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
            Row(
              children: [
                // Botón Ver Documento
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verDocumento(urlPermiso),
                    icon: Icon(urlPermiso != null ? Icons.description_outlined : Icons.cancel_outlined, size: 18),
                    label: Text(urlPermiso != null ? 'Ver Permiso' : 'Sin Archivo', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: urlPermiso != null ? PaletaColores.primary : Colors.grey,
                      side: BorderSide(color: urlPermiso != null ? PaletaColores.primary : Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Botón Aprobar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobarSolicitud(solicitud),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        color: Colors.red.withValues(alpha: 0.1),
        child: Text('Error pintando tarjeta: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }
}