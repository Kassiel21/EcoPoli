import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/repositorios/perfil_repositorio.dart';
import 'package:eco_poli/widgets/perfil/avatar_perfil_widget.dart';

/// Pantalla para cambiar la foto de perfil del usuario.
/// Permite tomar foto con cámara, elegir de galería o eliminar la foto actual.
/// Usa image_picker para seleccionar la imagen y Supabase Storage para guardarla.
class PantallaCambiarFoto extends StatefulWidget {
  const PantallaCambiarFoto({super.key});

  @override
  State<PantallaCambiarFoto> createState() => _PantallaCambiarFotoState();
}

class _PantallaCambiarFotoState extends State<PantallaCambiarFoto> {
  final _repositorio = PerfilRepositorio();
  final _picker = ImagePicker();

  File? _imagenSeleccionada; // Preview local antes de subir
  String? _urlFotoActual;    // URL guardada en Supabase
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarFotoActual();
  }

  /// Carga la URL de la foto actual desde Supabase
  Future<void> _cargarFotoActual() async {
    try {
      final perfil = await _repositorio.obtenerPerfil();
      if (mounted) setState(() => _urlFotoActual = perfil.fotoPerfil);
    } catch (e) {
      debugPrint('❌ Error cargando foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Foto de Perfil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── PREVIEW DEL AVATAR ─────────────────────────────────────────
            Center(
              child: AvatarPerfilWidget(
                urlFoto: _urlFotoActual,
                archivoLocal: _imagenSeleccionada,
                radio: 72,
                mostrarBotonEditar: true,
                onEditarTap: () => _mostrarOpcionesSeleccion(),
              ),
            ),
            const SizedBox(height: 32),

            // ── OPCIONES ───────────────────────────────────────────────────
            _opcionFoto(
              icono: Icons.photo_camera_outlined,
              titulo: 'Tomar foto',
              subtitulo: 'Usa la cámara de tu dispositivo',
              onTap: () => _seleccionarImagen(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _opcionFoto(
              icono: Icons.photo_library_outlined,
              titulo: 'Elegir de galería',
              subtitulo: 'Selecciona una imagen guardada',
              onTap: () => _seleccionarImagen(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _opcionFoto(
              icono: Icons.delete_outline,
              titulo: 'Eliminar foto',
              subtitulo: 'Volver a la imagen predeterminada',
              color: PaletaColores.error,
              onTap: _confirmarEliminarFoto,
            ),
            const SizedBox(height: 32),

            // ── BOTÓN GUARDAR (solo visible si hay imagen nueva) ───────────
            if (_imagenSeleccionada != null) _botonGuardar(),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS PRIVADOS ────────────────────────────────────────────────────────

  Widget _opcionFoto({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? PaletaColores.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: c, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: PaletaColores.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _botonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _cargando ? null : _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletaColores.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _cargando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ── LÓGICA ──────────────────────────────────────────────────────────────────

  /// Muestra un bottom sheet con las opciones de selección de imagen
  void _mostrarOpcionesSeleccion() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: PaletaColores.primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: PaletaColores.primary),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Abre la cámara o galería según la fuente indicada
  Future<void> _seleccionarImagen(ImageSource fuente) async {
    try {
      final imagen = await _picker.pickImage(
        source: fuente,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (imagen != null && mounted) {
        setState(() => _imagenSeleccionada = File(imagen.path));
      }
    } catch (e) {
      debugPrint('❌ Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo acceder a la cámara o galería'),
            backgroundColor: PaletaColores.error,
          ),
        );
      }
    }
  }

  /// Muestra diálogo de confirmación antes de eliminar la foto
  void _confirmarEliminarFoto() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Deseas eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarFoto();
            },
            child: Text('Eliminar', style: TextStyle(color: PaletaColores.error)),
          ),
        ],
      ),
    );
  }

  /// Elimina la foto de perfil en Supabase
  Future<void> _eliminarFoto() async {
    setState(() => _cargando = true);

    final error = await _repositorio.eliminarFotoPerfil();

    setState(() {
      _cargando = false;
      if (error == null) {
        _urlFotoActual = null;
        _imagenSeleccionada = null;
      }
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Foto eliminada correctamente'),
        backgroundColor: error != null ? PaletaColores.error : PaletaColores.primary,
      ),
    );
  }

  /// Sube la imagen seleccionada a Supabase Storage y actualiza el perfil
  Future<void> _guardar() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _cargando = true);

    try {
      final urlNueva = await _repositorio.subirFotoPerfil(_imagenSeleccionada!);
      setState(() {
        _urlFotoActual = urlNueva;
        _imagenSeleccionada = null;
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto actualizada correctamente'),
            backgroundColor: PaletaColores.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint('❌ Error subiendo foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al subir la foto. Intenta de nuevo.'),
            backgroundColor: PaletaColores.error,
          ),
        );
      }
    }
  }
}
