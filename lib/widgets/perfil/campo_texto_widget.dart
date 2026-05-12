import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

/// Campo de texto reutilizable con el estilo visual de EcoPoli.
/// Usado en las pantallas de perfil para mantener consistencia visual.
class CampoTextoWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final bool habilitado;
  final TextCapitalization capitalizacion;
  final String? Function(String?)? validador;
  final TextInputType tipoTeclado;

  const CampoTextoWidget({
    super.key,
    required this.controller,
    required this.hint,
    required this.icono,
    this.habilitado = true,
    this.capitalizacion = TextCapitalization.none,
    this.validador,
    this.tipoTeclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: habilitado,
      textCapitalization: capitalizacion,
      keyboardType: tipoTeclado,
      validator: validador,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: PaletaColores.textSecondary, fontSize: 14),
        prefixIcon: Icon(icono, color: PaletaColores.primary),
        filled: true,
        fillColor: habilitado
            ? PaletaColores.fieldBackground
            : PaletaColores.fieldBackground.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletaColores.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
