import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaCambiarFoto extends StatefulWidget {
  final String? urlActual; // 👇 Recibimos la foto actual

  const PantallaCambiarFoto({super.key, this.urlActual});

  @override
  State<PantallaCambiarFoto> createState() => _PantallaCambiarFotoState();
}

class _PantallaCambiarFotoState extends State<PantallaCambiarFoto> {
  final _supabase = Supabase.instance.client;
  File? _imagenSeleccionada;
  bool _estaCargando = false;

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    final picker = ImagePicker();
    try {
      final archivoEncontrado = await picker.pickImage(source: fuente, imageQuality: 100);
      if (archivoEncontrado != null) {
        CroppedFile? archivoRecortado = await ImageCropper().cropImage(
          sourcePath: archivoEncontrado.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Acomodar Foto',
                toolbarColor: PaletaColores.primary,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
                hideBottomControls: false),
            IOSUiSettings(title: 'Acomodar Foto', aspectRatioLockEnabled: true, resetButtonHidden: true),
          ],
        );
        if (archivoRecortado != null) {
          setState(() { _imagenSeleccionada = File(archivoRecortado.path); });
        }
      }
    } catch (e) {
      debugPrint('Error seleccionando/recortando imagen: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (_imagenSeleccionada == null) return;
    setState(() => _estaCargando = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final nombreArchivo = 'perfil_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rutaStorage = 'fotos/$nombreArchivo';

      await _supabase.storage.from('avatars').upload(rutaStorage, _imagenSeleccionada!, fileOptions: const FileOptions(upsert: true));
      final urlImagen = _supabase.storage.from('avatars').getPublicUrl(rutaStorage);

      await _supabase.from('usuarios').update({'url_foto': urlImagen}).eq('auth_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Foto actualizada!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir la imagen'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white, title: const Text('Foto de Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 72,
                backgroundColor: PaletaColores.fieldBackground,
                // 👇 Lógica inteligente para mostrar foto nueva, foto vieja, o ícono
                backgroundImage: _imagenSeleccionada != null 
                    ? FileImage(_imagenSeleccionada!) as ImageProvider
                    : (widget.urlActual != null ? NetworkImage(widget.urlActual!) : null),
                child: (_imagenSeleccionada == null && widget.urlActual == null)
                    ? Icon(Icons.person, size: 72, color: PaletaColores.primary.withValues(alpha: 0.5))
                    : null,
              ),
            ),
            const SizedBox(height: 32),
            _opcionBoton(Icons.camera_alt_outlined, 'Tomar Foto', () => _seleccionarImagen(ImageSource.camera)),
            const SizedBox(height: 12),
            _opcionBoton(Icons.photo_library_outlined, 'Elegir de Galería', () => _seleccionarImagen(ImageSource.gallery)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_imagenSeleccionada == null || _estaCargando) ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _estaCargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Nueva Foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcionBoton(IconData icono, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icono, color: PaletaColores.primary),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
      shape: RoundedRectangleBorder(side: BorderSide(color: PaletaColores.primary.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(12)),
    );
  }
}