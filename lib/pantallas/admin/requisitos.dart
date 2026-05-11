import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaRequisitos extends StatefulWidget {
  const PantallaRequisitos({super.key});

  @override
  State<PantallaRequisitos> createState() => _PantallaRequisitosState();
}

class _PantallaRequisitosState extends State<PantallaRequisitos> {
  final _supabase = Supabase.instance.client;
  
  // Controladores para todos los campos de tu tabla SQL
  final _controladorNombreBar = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _controladorReferencia = TextEditingController();
  
  late String _facultadSeleccionada = _facultades[0]; 
  
  // Manejo de archivos
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
    super.dispose();
  }

  // ── FUNCIÓN 1: SELECCIONAR EL ARCHIVO ──
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir la galería o archivos')));
      }
    }
  }

  // ── FUNCIÓN 2: ENVIAR SOLICITUD A SUPABASE ──
  Future<void> _enviarSolicitud() async {
    // 1. Validaciones
    if (_controladorNombreBar.text.trim().isEmpty || _controladorDescripcion.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena el nombre y la descripción del bar.')));
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

      // 2. Obtener el id_usuario interno de tu tabla 'usuarios'
      final datosUsuario = await _supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('auth_id', authUser.id)
          .single();
      
      final idUsuarioInterno = datosUsuario['id_usuario'];

      // 3. Subir el documento al Storage
      final nombreArchivoFinal = 'solicitud_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final rutaStorage = 'solicitudes/$nombreArchivoFinal';
      
      await _supabase.storage.from('documentos_bar').upload(
        rutaStorage,
        _documentoSeleccionado!,
        fileOptions: const FileOptions(upsert: true),
      );

      final urlPublica = _supabase.storage.from('documentos_bar').getPublicUrl(rutaStorage);

      // 4. Inserción en la tabla solicitudes_bar
      await _supabase.from('solicitudes_bar').insert({
        'id_usuario': idUsuarioInterno,
        'nombre_bar': _controladorNombreBar.text.trim(),
        'descripcion': _controladorDescripcion.text.trim(),
        'referencia': _controladorReferencia.text.trim(),
        'latitud': -1.6587, // Coordenadas temporales ESPOCH
        'longitud': -78.6773,
        'imagen_url': urlPublica,
        'estado': 'pendiente',
      });

      // 5. Mensaje de éxito y salir (Corregido)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solicitud enviada con éxito!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Cierra la pantalla y vuelve al perfil
      }

    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar: $e'), backgroundColor: Colors.red)
        );
      }
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
            Text(
              'Llena los datos de tu local y adjunta el permiso emitido por la ESPOCH. '
              'Una vez validada tu documentación, se habilitarán tus funciones de administrador.',
              style: TextStyle(fontSize: 14, color: PaletaColores.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 30),

            // ── FORMULARIO DE DATOS ──
            const Text('Datos del Establecimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _controladorNombreBar,
              decoration: InputDecoration(
                labelText: 'Nombre del bar *',
                prefixIcon: const Icon(Icons.storefront),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controladorDescripcion,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Descripción del bar *',
                prefixIcon: const Icon(Icons.fastfood_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // DropdownButton limpio para evitar el error de "deprecated"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _facultadSeleccionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: _facultades.map((String facultad) {
                    return DropdownMenuItem<String>(value: facultad, child: Text(facultad, style: const TextStyle(fontSize: 14)));
                  }).toList(),
                  onChanged: (String? nuevoValor) {
                    if (nuevoValor != null) {
                      setState(() => _facultadSeleccionada = nuevoValor);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controladorReferencia,
              decoration: InputDecoration(
                labelText: 'Referencia de ubicación (Ej: Junto a biblioteca)',
                prefixIcon: const Icon(Icons.map_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // ── SECCIÓN DE DOCUMENTOS ──
            const Text('Documentación Requerida *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _itemRequisito(Icons.description_outlined, 'Permiso ESPOCH', 'Documento oficial en PDF '),
            
            const SizedBox(height: 20),

            // ── ZONA DE CARGA DE ARCHIVO ──
            GestureDetector(
              onTap: _seleccionarDocumento,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _documentoSeleccionado == null ? PaletaColores.primary.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _documentoSeleccionado == null ? PaletaColores.primary.withValues(alpha: 0.3) : Colors.green,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _documentoSeleccionado == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline, 
                      size: 40, 
                      color: _documentoSeleccionado == null ? PaletaColores.primary : Colors.green
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nombreArchivo ?? 'Toca aquí para buscar el archivo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: _documentoSeleccionado == null ? PaletaColores.primary : Colors.green
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── BOTÓN ENVIAR SOLICITUD ──
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _estaCargando ? null : _enviarSolicitud,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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

  Widget _itemRequisito(IconData icono, String titulo, String descripcion) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: PaletaColores.fieldBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: PaletaColores.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: PaletaColores.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(descripcion, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}