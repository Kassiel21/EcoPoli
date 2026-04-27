import 'package:flutter/material.dart';

/// Paleta de colores oficial de EcoPoli
/// Centralizamos los colores aquí para no repetirlos en cada pantalla.
/// Si el diseño cambia, solo modificamos este archivo.
class PaletaColores {
  // Constructor privado: esta clase no se instancia, solo se usa como referencia
  PaletaColores._();

  // Verde principal (botones, acentos)
  static const Color primary = Color(0xFF2E7D32);

  // Verde claro (fondos de campos de texto)
  static const Color fieldBackground = Color(0xFFE8F5E9);

  // Verde para textos de enlace
  static const Color linkText = Color(0xFF388E3C);

  // Fondo general de la app (blanco)
  static const Color background = Color(0xFFFFFFFF);

  // Texto principal (oscuro)
  static const Color textPrimary = Color(0xFF1B1B1B);

  // Texto secundario (gris)
  static const Color textSecondary = Color(0xFF757575);

  // Color de error
  static const Color error = Color(0xFFD32F2F);
}