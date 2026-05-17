import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:eco_poli/pantallas/mapa_selector.dart'; 

class PantallaRequisitos extends StatefulWidget {
  const PantallaRequisitos({super.key});

  @override
  State<PantallaRequisitos> createState() => _PantallaRequisitosState();
}

class _PantallaRequisitosState extends State<PantallaRequisitos> {
  final _supabase = Supabase.instance.client;
  
  final _controladorNombreBar = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _controladorReferencia = TextEditingController();
  final _controladorDescripcionUbicacion = TextEditingController();

  //  VARIABLES DE MAPA 
  double? _latitudSeleccionada;
  double? _longitudSeleccionada;
  
  late String _facultadSeleccionada = _facultades[0]; 
  
  File? _documentoSeleccionado;
  String? _nombreArchivo;
  bool _estaCargando = false;

  final List<String> _facultades = [
    'Facultad de Informática y Electrónica (FIE)',
    'Facultad de Mecánica',
    'Facultad de Ciencias',
    'Facultad de Administración de Empresas',
    'Facultad de Salud Pública',
    'Facultad de Ciencias Pecuarias',
    'Facultad de Recursos Naturales',
  ];

  @override
  void dispose() {
    _controladorNombreBar.dispose();
    _controladorDescripcion.dispose();
    _controladorReferencia.dispose();
    _controladorDescripcionUbicacion.dispose();
    super.dispose();
  }

  Future<void> _seleccionarDocumento() async {
    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (resultado != null) {
        setState(() {
          _documentoSeleccionado = File(resultado.files.single.path!);
          _nombreArchivo = resultado.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir archivos')));
    }
  }

  Future<void> _enviarSolicitud() async {
    // 👇 VALIDACIÓN DEL MAPA AÑADIDA
    if (_controladorNombreBar.text.trim().isEmpty || _controladorDescripcion.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena el nombre y la descripción del bar.')));
      return;
    }
    if (_latitudSeleccionada == null || _longitudSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Debes seleccionar la ubicación en el mapa.')));
      return;
    }
    if (_documentoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Es obligatorio adjuntar el permiso legal.')));
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) throw Exception('Sesión no encontrada');

      final datosUsuario = await _supabase.from('usuarios').select('id_usuario').eq('auth_id', authUser.id).single();
      final idUsuarioInterno = datosUsuario['id_usuario'];

      final nombreArchivoFinal = 'solicitud_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final rutaStorage = 'solicitudes/$nombreArchivoFinal';
      
      await _supabase.storage.from('documentos_bar').upload(
        rutaStorage,
        _documentoSeleccionado!,
        fileOptions: const FileOptions(upsert: true),
      );

      final urlPublica = _supabase.storage.from('documentos_bar').getPublicUrl(rutaStorage);

      // 👇 INSERCIÓN CON LAS COORDENADAS REALES
      await _supabase.from('solicitudes_bar').insert({
        'id_usuario': idUsuarioInterno,
        'nombre_bar': _controladorNombreBar.text.trim(),
        'descripcion': _controladorDescripcion.text.trim(),
        'referencia': _controladorReferencia.text.trim(),
        'latitud': _latitudSeleccionada,    // Coordenada real
        'longitud': _longitudSeleccionada,  // Coordenada real
        'documento_url': urlPublica,        // Corregido el nombre a documento_url
        'estado': 'pendiente',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Solicitud enviada con éxito!'), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }

    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo enviar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Solicitud de Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activa tu Perfil Comercial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary)),
            const SizedBox(height: 12),
            Text('Llena los datos de tu local y adjunta el permiso emitido por la ESPOCH.', style: TextStyle(fontSize: 14, color: PaletaColores.textSecondary, height: 1.5)),
            const SizedBox(height: 30),

            const Text('Datos del Establecimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _controladorNombreBar,
              decoration: InputDecoration(labelText: 'Nombre del bar *', prefixIcon: const Icon(Icons.storefront), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controladorDescripcion,
              maxLines: 2,
              decoration: InputDecoration(labelText: 'Descripción del bar *', prefixIcon: const Icon(Icons.fastfood_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _facultadSeleccionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _facultades.map((String facultad) => DropdownMenuItem<String>(value: facultad, child: Text(facultad, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (String? nuevoValor) { if (nuevoValor != null) setState(() => _facultadSeleccionada = nuevoValor); },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controladorReferencia,
              decoration: InputDecoration(labelText: 'Referencia de ubicación', prefixIcon: const Icon(Icons.map_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 30),

            // 👇 SECCIÓN MAPA REEMPLAZADA POR BOTÓN INTERACTIVO
            const Text('Ubicación en el Mapa *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _latitudSeleccionada == null ? Colors.grey.shade400 : PaletaColores.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: _latitudSeleccionada == null ? Colors.white : PaletaColores.primary.withValues(alpha: 0.1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Icon(
                  _latitudSeleccionada == null ? Icons.map_outlined : Icons.location_on, 
                  color: _latitudSeleccionada == null ? Colors.grey : PaletaColores.primary,
                  size: 32,
                ),
                title: Text(
                  _latitudSeleccionada == null ? 'Fijar ubicación del local' : 'Ubicación Confirmada', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: _latitudSeleccionada == null ? Colors.black87 : PaletaColores.primary)
                ),
                subtitle: _latitudSeleccionada != null 
                    ? Text('Las coordenadas han sido guardadas') 
                    : const Text('Abre el mapa para colocar el pin'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Abre la pantalla del mapa que hicimos en el mensaje anterior
                  final LatLng? coordenadas = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaMapaSelector()),
                  );
                  
                  if (coordenadas != null) {
                    setState(() {
                      _latitudSeleccionada = coordenadas.latitude;
                      _longitudSeleccionada = coordenadas.longitude;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 30),

            const Text('Documentación Requerida *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: _seleccionarDocumento,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _documentoSeleccionado == null ? PaletaColores.primary.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: _documentoSeleccionado == null ? PaletaColores.primary.withValues(alpha: 0.3) : Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(_documentoSeleccionado == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline, size: 40, color: _documentoSeleccionado == null ? PaletaColores.primary : Colors.green),
                    const SizedBox(height: 12),
                    Text(_nombreArchivo ?? 'Toca aquí para subir el PDF de permiso', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _documentoSeleccionado == null ? PaletaColores.primary : Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _estaCargando ? null : _enviarSolicitud,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _estaCargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar Solicitud a Revisión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}