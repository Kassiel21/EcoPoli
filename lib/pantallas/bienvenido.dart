import 'package:eco_poli/pantallas/home.dart';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/config/autenticacion.dart';

class PantallaBienvenido extends StatefulWidget {
  const PantallaBienvenido({super.key});

  @override
  State<PantallaBienvenido> createState() => _PantallaBienvenidoState();
}

class _PantallaBienvenidoState extends State<PantallaBienvenido> {
  // ── ESTADO ───────────────────────────────────────────────
  final _servicioAuth = Autenticacion();
  String _nombre = '';        // nombre del usuario
  bool _cargando = true;      // mientras consulta Supabase

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  // Se ejecuta automáticamente al abrir la pantalla
  Future<void> _cargarNombre() async {
    final nombre = await _servicioAuth.obtenerNombreUsuario();
    setState(() {
      _nombre = nombre;
      _cargando = false;
    });
  }

  // ════════════════════════════════════════════════════════
  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: SafeArea(
        child: Center(
          child: _cargando
              // Mientras carga el nombre muestra un spinner
              ? CircularProgressIndicator(color: PaletaColores.primary)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── LOGO ───────────────────────────────
                    Image.asset(
                      'recursos/logo2.png',
                      height: 210,
                    ),
                    const SizedBox(height: 32),

                    // ── SALUDO ─────────────────────────────
                    Text(
                      '¡Hola, $_nombre!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: PaletaColores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── BOTÓN FLECHA ───────────────────────
                    GestureDetector(
                      onTap: () {
                        //  navegación al Home
                        debugPrint('→ Ir al Home');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PantallaHome(),
                          ),
                        );
                      },
                      child: Container(
                        width: 95,
                        height: 64,
                        decoration: BoxDecoration(
                          color: PaletaColores.fieldBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: PaletaColores.primary,
                          size: 35,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}