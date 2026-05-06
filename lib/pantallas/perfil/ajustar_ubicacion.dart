import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/repositorios/perfil_repositorio.dart';
import 'package:eco_poli/widgets/perfil/campo_texto_widget.dart';

/// Pantalla para ajustar la ubicación del usuario.
/// Permite ingresar ciudad y dirección manualmente o detectar la ubicación
/// actual del dispositivo usando el GPS (geolocator).
class PantallaAjustarUbicacion extends StatefulWidget {
  const PantallaAjustarUbicacion({super.key});

  @override
  State<PantallaAjustarUbicacion> createState() => _PantallaAjustarUbicacionState();
}

class _PantallaAjustarUbicacionState extends State<PantallaAjustarUbicacion> {
  final _ciudadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _repositorio = PerfilRepositorio();

  bool _cargando = false;
  bool _cargandoGps = false;
  bool _usarUbicacionActual = false;

  @override
  void initState() {
    super.initState();
    _cargarUbicacionActual();
  }

  /// Carga la ubicación guardada previamente en Supabase
  Future<void> _cargarUbicacionActual() async {
    try {
      final perfil = await _repositorio.obtenerPerfil();
      if (mounted) {
        _ciudadController.text = perfil.ciudad ?? '';
        _direccionController.text = perfil.direccion ?? '';
      }
    } catch (e) {
      debugPrint('❌ Error cargando ubicación: $e');
    }
  }

  @override
  void dispose() {
    _ciudadController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Ajustar Ubicación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── MAPA PLACEHOLDER ───────────────────────────────────────────
              _mapaPlaceholder(),
              const SizedBox(height: 20),

              // ── SWITCH GPS ─────────────────────────────────────────────────
              _switchGps(),
              const SizedBox(height: 20),

              // ── CAMPOS MANUALES ────────────────────────────────────────────
              Text(
                'O ingresa manualmente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PaletaColores.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              CampoTextoWidget(
                controller: _ciudadController,
                hint: 'Ciudad',
                icono: Icons.location_city_outlined,
                capitalizacion: TextCapitalization.words,
                habilitado: !_usarUbicacionActual,
                validador: (v) {
                  if (!_usarUbicacionActual && (v == null || v.trim().isEmpty)) {
                    return 'Ingresa tu ciudad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CampoTextoWidget(
                controller: _direccionController,
                hint: 'Dirección o sector',
                icono: Icons.place_outlined,
                capitalizacion: TextCapitalization.sentences,
                habilitado: !_usarUbicacionActual,
              ),
              const SizedBox(height: 32),

              // ── BOTÓN GUARDAR ──────────────────────────────────────────────
              _botonGuardar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS PRIVADOS ────────────────────────────────────────────────────────

  Widget _mapaPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        color: PaletaColores.fieldBackground,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: PaletaColores.primary.withValues(alpha: 0.25),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PaletaColores.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ver mapa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchGps() {
    return Container(
      decoration: BoxDecoration(
        color: PaletaColores.fieldBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        value: _usarUbicacionActual,
        onChanged: _cargandoGps
            ? null
            : (v) {
                setState(() => _usarUbicacionActual = v);
                if (v) _obtenerUbicacionGps();
              },
        // activeThumbColor reemplaza el deprecated activeColor
        activeTrackColor: PaletaColores.primary.withValues(alpha: 0.5),
        activeColor: PaletaColores.primary,
        title: const Text(
          'Usar mi ubicación actual',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _cargandoGps ? 'Obteniendo ubicación...' : 'Detectar automáticamente',
          style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary),
        ),
        secondary: _cargandoGps
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaletaColores.primary,
                ),
              )
            : Icon(Icons.gps_fixed, color: PaletaColores.primary),
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
                'Guardar ubicación',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ── LÓGICA ──────────────────────────────────────────────────────────────────

  /// Solicita permisos y obtiene la posición GPS del dispositivo.
  /// Nota: la geocodificación inversa (coordenadas → dirección) requiere
  /// el paquete `geocoding` que puede agregarse en una iteración futura.
  Future<void> _obtenerUbicacionGps() async {
    setState(() => _cargandoGps = true);

    try {
      // Verificar si el servicio de ubicación está habilitado
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        _mostrarError('El GPS está desactivado. Actívalo en ajustes.');
        setState(() {
          _cargandoGps = false;
          _usarUbicacionActual = false;
        });
        return;
      }

      // Verificar y solicitar permisos
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mostrarError('Permiso de ubicación denegado.');
          setState(() {
            _cargandoGps = false;
            _usarUbicacionActual = false;
          });
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        _mostrarError('Permiso denegado permanentemente. Habilítalo en ajustes.');
        setState(() {
          _cargandoGps = false;
          _usarUbicacionActual = false;
        });
        return;
      }

      // Obtener posición actual
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Mostrar coordenadas en los campos (geocodificación inversa pendiente)
      if (mounted) {
        _ciudadController.text = 'Lat: ${posicion.latitude.toStringAsFixed(4)}';
        _direccionController.text = 'Lng: ${posicion.longitude.toStringAsFixed(4)}';
        setState(() => _cargandoGps = false);
      }
    } catch (e) {
      debugPrint('❌ Error GPS: $e');
      if (mounted) {
        _mostrarError('No se pudo obtener la ubicación. Intenta manualmente.');
        setState(() {
          _cargandoGps = false;
          _usarUbicacionActual = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: PaletaColores.error),
    );
  }

  /// Valida y guarda la ubicación en Supabase
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await _repositorio.actualizarUbicacion(
      ciudad: _ciudadController.text,
      direccion: _direccionController.text,
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: PaletaColores.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ubicación guardada correctamente'),
          backgroundColor: PaletaColores.primary,
        ),
      );
      Navigator.pop(context);
    }
  }
}
