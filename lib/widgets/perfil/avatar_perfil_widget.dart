import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

/// Widget reutilizable que muestra el avatar del usuario.
/// Soporta imagen de red (URL), imagen local (File) y placeholder con ícono.
class AvatarPerfilWidget extends StatelessWidget {
  /// URL de la foto de perfil almacenada en Supabase Storage
  final String? urlFoto;

  /// Archivo local seleccionado antes de subir (preview)
  final File? archivoLocal;

  /// Radio del círculo del avatar
  final double radio;

  /// Si es true, muestra el ícono de cámara para indicar que es editable
  final bool mostrarBotonEditar;

  /// Callback al presionar el botón de editar
  final VoidCallback? onEditarTap;

  const AvatarPerfilWidget({
    super.key,
    this.urlFoto,
    this.archivoLocal,
    this.radio = 48,
    this.mostrarBotonEditar = false,
    this.onEditarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radio,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          backgroundImage: _resolverImagen(),
          child: _resolverImagen() == null
              ? Icon(Icons.person, size: radio, color: Colors.white)
              : null,
        ),
        if (mostrarBotonEditar)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onEditarTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PaletaColores.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  /// Resuelve qué imagen mostrar según la prioridad:
  /// 1. Archivo local (preview antes de subir)
  /// 2. URL de red (foto guardada en Supabase)
  /// 3. null → muestra el ícono placeholder
  ImageProvider? _resolverImagen() {
    if (archivoLocal != null) return FileImage(archivoLocal!);
    if (urlFoto != null && urlFoto!.isNotEmpty) return NetworkImage(urlFoto!);
    return null;
  }
}
