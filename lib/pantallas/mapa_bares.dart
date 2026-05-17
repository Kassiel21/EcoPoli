import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:eco_poli/config/ruta_servicio.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:eco_poli/modelos/bar_modelo.dart';
import 'package:eco_poli/modelos/producto_modelo.dart';
import 'package:eco_poli/config/ubicacion_servicio.dart';

import 'package:eco_poli/repositorios/productos_repositorio.dart';
import 'package:eco_poli/repositorios/bares_repositorio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaMapaBares extends StatefulWidget {
  const PantallaMapaBares({super.key});

  @override
  State<PantallaMapaBares> createState() => _PantallaMapaBaresState();
}

class _PantallaMapaBaresState extends State<PantallaMapaBares> with TickerProviderStateMixin {
  final UbicacionServicio _ubicacionServicio = UbicacionServicio();
  final RutaServicio _rutaServicio = RutaServicio();
  final ProductosRepositorio _productosRepositorio = ProductosRepositorio();
  final BaresRepositorio _baresRepositorio = BaresRepositorio();
  
  LatLng? _ubicacionUsuario;
  bool _rutaActiva = false;
  bool _mapaCentrado = false;
  bool _seguirUsuario = false;
  bool _mostrarSatelite = false;
  
  final MapController _mapController = MapController();
  List<ProductoModelo> _productosBar = [];
  bool _cargandoProductos = false;
  
  StreamSubscription<Position>? _ubicacionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  
  List<LatLng> _puntosRuta = [];
  Timer? _recalculoRutaTimer;
  LatLng? _ultimaUbicacionParaRuta;
  bool _calculandoRuta = false;
  int _distanciaRuta = 0;
  int _tiempoRuta = 0;
  
  // NAVEGACIÓN GIRO A GIRO
  List<Map<String, dynamic>> _pasosRuta = [];
  int _pasoActualIndex = 0;
  String _instruccionActual = 'Calculando ruta...';
  
  String _busquedaTexto = '';
  List<BarModelo> _baresFiltrados = [];
  bool _buscandoGlobal = false;
  List<Map<String, dynamic>> _resultadosGlobales = [];
  Timer? _debounceBusqueda;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  double _headingUsuario = 0.0;
  double _compassHeading = 0.0;
  double _mapRotation = 0.0;
  
  bool _cargandoBares = false;
  String? _errorCargaBares;
  List<BarModelo> _bares = [];

  LatLng? _destinoRutaActual;
  String? _nombreDestinoRuta;
  LatLng? _pinManual;
  String? _direccionPinManual;
  bool _obteniendoDireccion = false;

  late AnimationController _rotationController;
  Animation<double>? _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cargarUbicacionGuardada();
    _cargarBares();
    _iniciarBrujula();
    
    _mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {
          _mapRotation = _mapController.camera.rotation;
        });
      }
    });
  }

  void _iniciarBrujula() {
    _compassStream = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          final double newHeading = event.heading!;
          if ((newHeading - _compassHeading).abs() > 1.5) {
            _compassHeading = newHeading;
          }
        });
      }
    });
  }

  Future<void> _cargarUbicacionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('ubicacion_lat');
    final lng = prefs.getDouble('ubicacion_lng');
    
    if (lat != null && lng != null) {
      setState(() {
        _ubicacionUsuario = LatLng(lat, lng);
        _mapController.move(_ubicacionUsuario!, 17.0);
        _mapaCentrado = true;
      });
      _iniciarStreamUbicacion();
    } else {
      _cargarUbicacion();
    }
  }

  Future<void> _guardarUbicacion(LatLng ubicacion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ubicacion_lat', ubicacion.latitude);
    await prefs.setDouble('ubicacion_lng', ubicacion.longitude);
  }

  Future<void> _cargarUbicacion() async {
    try {
      final posicion = await _ubicacionServicio.obtenerUbicacionActual();
      if (posicion != null && mounted) {
        final ubicacion = LatLng(posicion.latitude, posicion.longitude);
        setState(() {
          _ubicacionUsuario = ubicacion;
        });
        
        _mapController.move(ubicacion, _rutaActiva ? 18.0 : 17.0);
        _mapaCentrado = true;

        if (_ubicacionStream == null) {
          _iniciarStreamUbicacion();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, enciende el GPS de tu teléfono.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _iniciarStreamUbicacion() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2,
    );

    _ubicacionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        if (mounted) {
          final nuevaUbicacion = LatLng(position.latitude, position.longitude);
          final heading = position.heading;
          
          setState(() {
            _ubicacionUsuario = nuevaUbicacion;
            _headingUsuario = heading;
          });
          
          _guardarUbicacion(nuevaUbicacion);

          if (_seguirUsuario) {
            _mapController.move(nuevaUbicacion, _mapController.camera.zoom, id: 'follow-user');
          }
          
          // Lógica de Giro a Giro (Turn-by-turn)
          if (_rutaActiva && _pasosRuta.isNotEmpty && _pasoActualIndex < _pasosRuta.length) {
            final sigPasoCoord = _pasosRuta[_pasoActualIndex]['coordenada'] as LatLng;
            final distAlPaso = Distance().as(
              LengthUnit.Meter,
              nuevaUbicacion,
              sigPasoCoord,
            );
            
            // Si nos acercamos a la maniobra, pasar a la siguiente instrucción
            if (distAlPaso < 20) {
              final sigIndex = _pasoActualIndex + 1;
              if (sigIndex < _pasosRuta.length) {
                setState(() {
                  _pasoActualIndex = sigIndex;
                  _instruccionActual = _pasosRuta[sigIndex]['instruccion'];
                });
              }
            }
          }

          if (_rutaActiva && _ultimaUbicacionParaRuta != null && _destinoRutaActual != null) {
            final distancia = Distance().as(
              LengthUnit.Meter,
              _ultimaUbicacionParaRuta!,
              nuevaUbicacion,
            );

            if (distancia > 50) {
              _recalculoRutaTimer?.cancel();
              _recalculoRutaTimer = Timer(const Duration(seconds: 2), () {
                if (mounted && _rutaActiva) {
                  _ultimaUbicacionParaRuta = nuevaUbicacion;
                  _calcularRutaOSRM(_destinoRutaActual!);
                }
              });
            }
          }

          if (_destinoRutaActual != null) {
            final distanciaDestino = Distance().as(
              LengthUnit.Meter,
              nuevaUbicacion,
              _destinoRutaActual!,
            );
            
            if (distanciaDestino < 15) {
              _cancelarRuta();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Has llegado a tu destino'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _ubicacionStream?.cancel();
    _compassStream?.cancel();
    _recalculoRutaTimer?.cancel();
    _rotationController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _animarRotacionMapa(double anguloDestino) {
    final double anguloActual = _mapController.camera.rotation;
    
    double diferencia = anguloDestino - anguloActual;
    while (diferencia > 180) diferencia -= 360;
    while (diferencia < -180) diferencia += 360;
    
    _rotationAnimation = Tween<double>(
      begin: anguloActual,
      end: anguloActual + diferencia,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutQuart,
    ))..addListener(() {
      _mapController.rotate(_rotationAnimation!.value);
    });
    
    _rotationController.forward(from: 0.0);
  }

  Future<void> _onLongPressMap(TapPosition tapPosition, LatLng point) async {
    if (_rutaActiva) return;
    
    setState(() {
      _pinManual = point;
      _direccionPinManual = null;
      _obteniendoDireccion = true;
      _busquedaTexto = '';
      _searchController.clear();
      _searchFocus.unfocus();
    });

    final direccion = await _ubicacionServicio.obtenerDireccion(point);
    
    if (mounted) {
      setState(() {
        _obteniendoDireccion = false;
        _direccionPinManual = direccion ?? 'Ubicación seleccionada';
      });
      _mostrarBottomSheetUbicacionManual(point, _direccionPinManual!);
    }
  }

  Future<void> _iniciarRutaHacia(LatLng destino, String nombreDestino) async {
    setState(() {
      _destinoRutaActual = destino;
      _nombreDestinoRuta = nombreDestino;
      _rutaActiva = true;
      _seguirUsuario = true;
      _puntosRuta = [];
      _pasosRuta = [];
      _instruccionActual = 'Calculando ruta...';
      _busquedaTexto = '';
      _searchController.clear();
      _searchFocus.unfocus();
    });

    if (_ubicacionUsuario != null) {
      _mapController.move(_ubicacionUsuario!, 18.0);
      _ultimaUbicacionParaRuta = _ubicacionUsuario;
      await _calcularRutaOSRM(destino);
    } else {
      _cargarUbicacion();
    }
  }

  void _cancelarRuta() {
    _recalculoRutaTimer?.cancel();
    setState(() {
      _destinoRutaActual = null;
      _nombreDestinoRuta = null;
      _rutaActiva = false;
      _seguirUsuario = false;
      _puntosRuta = [];
      _pasosRuta = [];
      _pasoActualIndex = 0;
      _ultimaUbicacionParaRuta = null;
      _distanciaRuta = 0;
      _tiempoRuta = 0;
    });
    
    if (_ubicacionUsuario != null) {
      _mapController.move(_ubicacionUsuario!, 16.0);
    }
  }

  void _centrarUbicacion() {
    _cargarUbicacion();
    if (_ubicacionUsuario != null) {
      setState(() {
        _seguirUsuario = true;
      });
      _animarRotacionMapa(0.0);
    }
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _toggleCapa() {
    setState(() {
      _mostrarSatelite = !_mostrarSatelite;
    });
  }

  Future<void> _calcularRutaOSRM(LatLng destino) async {
    if (_ubicacionUsuario == null) return;

    setState(() {
      _calculandoRuta = true;
    });

    final rutaData = await _rutaServicio.obtenerRutaOSRM(
      _ubicacionUsuario!,
      destino,
    );

    if (mounted && rutaData != null) {
      setState(() {
        _puntosRuta = rutaData['puntos'] as List<LatLng>;
        _distanciaRuta = rutaData['distancia'] as int;
        _tiempoRuta = rutaData['duracion'] as int;
        _pasosRuta = rutaData['pasos'] as List<Map<String, dynamic>>? ?? [];
        _pasoActualIndex = 0;
        
        if (_pasosRuta.isNotEmpty) {
          _instruccionActual = _pasosRuta[0]['instruccion'];
        } else {
          _instruccionActual = 'Sigue la ruta';
        }
        
        _calculandoRuta = false;
      });
    } else if (mounted) {
      setState(() {
        _calculandoRuta = false;
        _instruccionActual = 'Error al calcular ruta';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo calcular la ruta.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatearDistancia(int metros) {
    if (metros >= 1000) {
      final km = metros / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '$metros m';
  }

  String _formatearTiempo(int segundos) {
    final minutos = (segundos / 60).round();
    if (minutos > 60) {
      final horas = minutos ~/ 60;
      final mins = minutos % 60;
      return '$horas h $mins min';
    }
    return '$minutos min';
  }

  Future<void> _cargarBares() async {
    setState(() {
      _cargandoBares = true;
      _errorCargaBares = null;
    });

    try {
      final bares = await _baresRepositorio.obtenerBaresActivos();
      if (mounted) {
        setState(() {
          _bares = bares;
          _baresFiltrados = bares;
          _cargandoBares = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoBares = false;
          _errorCargaBares = e.toString();
        });
      }
    }
  }

  void _filtrarBaresGlobal(String texto) {
    setState(() {
      _busquedaTexto = texto;
      if (texto.isEmpty) {
        _baresFiltrados = _bares;
        _resultadosGlobales = [];
      } else {
        _baresFiltrados = _bares
            .where((bar) => bar.nombre.toLowerCase().contains(texto.toLowerCase()))
            .toList();
      }
    });

    if (texto.length > 3) {
      if (_debounceBusqueda?.isActive ?? false) _debounceBusqueda!.cancel();
      _debounceBusqueda = Timer(const Duration(milliseconds: 800), () async {
        setState(() {
          _buscandoGlobal = true;
        });
        
        final resultados = await _ubicacionServicio.buscarLugares(texto);
        
        if (mounted) {
          setState(() {
            _resultadosGlobales = resultados;
            _buscandoGlobal = false;
          });
        }
      });
    }
  }

  List<BarModelo> _obtenerBaresOrdenadosPorCercania() {
    if (_ubicacionUsuario == null) return _baresFiltrados;
    
    final baresConDistancia = _baresFiltrados.map((bar) {
      final distance = Distance();
      final metros = distance.as(
        LengthUnit.Meter,
        _ubicacionUsuario!,
        bar.coordenadas,
      );
      return {'bar': bar, 'distancia': metros};
    }).toList();
    
    baresConDistancia.sort((a, b) => (a['distancia'] as double).compareTo(b['distancia'] as double));
    
    return baresConDistancia.map((item) => item['bar'] as BarModelo).toList();
  }

  Future<void> _mostrarBottomSheetUbicacionManual(LatLng punto, String direccion) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destino',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        direccion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _iniciarRutaHacia(punto, direccion);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions),
                    SizedBox(width: 8),
                    Text(
                      'Iniciar Navegación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarBottomSheetBar(BarModelo bar) async {
    final descripcion = bar.descripcion ?? 'Punto de reciclaje';
    
    setState(() {
      _cargandoProductos = true;
      _productosBar = [];
    });

    final todosLosProductos = await _productosRepositorio.obtenerTodosLosProductos();
    final productosAleatorios = _productosRepositorio.seleccionarProductosAleatorios(todosLosProductos);

    if (mounted) {
      setState(() {
        _cargandoProductos = false;
        _productosBar = productosAleatorios;
      });
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (bar.imagenBar != null && bar.imagenBar!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  bar.imagenBar!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: PaletaColores.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.store,
                  size: 64,
                  color: PaletaColores.primary,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaletaColores.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.recycling,
                    color: PaletaColores.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bar.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              descripcion,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _iniciarRutaHacia(bar.coordenadas, bar.nombre);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions),
                    SizedBox(width: 8),
                    Text('Iniciar Ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centroMapa = _ubicacionUsuario ?? const LatLng(-1.6645, -78.6550);
    final baresAMostrar = _obtenerBaresOrdenadosPorCercania();
    
    final double mapRotationAbs = _mapRotation.abs();
    final bool showCompass = mapRotationAbs > 2.0 && mapRotationAbs < 358.0;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centroMapa,
              initialZoom: 16.0,
              onLongPress: _onLongPressMap,
            ),
            children: [
              TileLayer(
                urlTemplate: _mostrarSatelite 
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.eco_poli',
              ),
              if (_ubicacionUsuario != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionUsuario!,
                      width: 140,
                      height: 140,
                      child: Transform.rotate(
                        angle: (_compassHeading - _mapRotation) * 0.0174533,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 0,
                              child: CustomPaint(
                                size: const Size(140, 140),
                                painter: ConoDireccionalPainter(),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4285F4),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4285F4).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (_pinManual != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinManual!,
                      width: 60,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.black87,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              if (_rutaActiva && _puntosRuta.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _puntosRuta,
                      strokeWidth: 8.0, // Más grueso
                      color: const Color(0xFF4285F4).withValues(alpha: 0.9),
                      borderStrokeWidth: 3.0, // Borde ancho oscuro
                      borderColor: const Color(0xFF174EA6),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              if (!_rutaActiva)
                MarkerLayer(
                  markers: baresAMostrar.map((bar) {
                    return Marker(
                      point: bar.coordenadas,
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _mostrarBottomSheetBar(bar),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: PaletaColores.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: PaletaColores.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                bar.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _rutaActiva ? 120 : 120,
            right: showCompass ? 16 : -60,
            child: GestureDetector(
              onTap: () => _animarRotacionMapa(0.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -_mapRotation * 0.0174533,
                      child: const Icon(
                        Icons.explore,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (!_rutaActiva) ...[
            Positioned(
              top: 180,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'layer_btn',
                    onPressed: _toggleCapa,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _mostrarSatelite ? Icons.map : Icons.satellite, 
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_btn',
                    onPressed: _zoomIn,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_btn',
                    onPressed: _zoomOut,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black87),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _filtrarBaresGlobal,
                      decoration: InputDecoration(
                        hintText: '🔍 Buscar calles o bares...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _busquedaTexto.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filtrarBaresGlobal('');
                                  _searchFocus.unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  
                  if (_busquedaTexto.isNotEmpty && (_baresFiltrados.isNotEmpty || _resultadosGlobales.isNotEmpty || _buscandoGlobal))
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            if (_baresFiltrados.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.grey.shade100,
                                child: const Text('Bares Recomendados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              ..._baresFiltrados.map((bar) => ListTile(
                                leading: const Icon(Icons.store, color: PaletaColores.primary),
                                title: Text(bar.nombre),
                                onTap: () {
                                  _searchFocus.unfocus();
                                  _mapController.move(bar.coordenadas, 17.0);
                                  _mostrarBottomSheetBar(bar);
                                },
                              )),
                            ],
                            
                            if (_busquedaTexto.length > 3) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.grey.shade100,
                                child: const Text('Lugares Globales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              if (_buscandoGlobal)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_resultadosGlobales.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No se encontraron lugares en la red.'),
                                )
                              else
                                ..._resultadosGlobales.map((lugar) => ListTile(
                                  leading: const Icon(Icons.public, color: Colors.blue),
                                  title: Text(lugar['nombre'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(lugar['descripcion'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                                  onTap: () {
                                    _searchFocus.unfocus();
                                    final coords = lugar['coordenadas'] as LatLng;
                                    _mapController.move(coords, 17.0);
                                    _onLongPressMap(const TapPosition(Offset(0,0), Offset(0,0)), coords);
                                  },
                                )),
                            ]
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (_rutaActiva) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F9D58),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _instruccionActual,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_calculandoRuta)
                            const Text(
                              'Calculando ruta...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatearTiempo(_tiempoRuta),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F9D58),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_formatearDistancia(_distanciaRuta)})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'close_nav_btn',
                      onPressed: _cancelarRuta,
                      backgroundColor: Colors.red.shade100,
                      elevation: 0,
                      child: const Icon(Icons.close, color: Colors.red, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _rutaActiva ? 120.0 : 0.0),
        child: FloatingActionButton(
          onPressed: _centrarUbicacion,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4285F4),
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}

class ConoDireccionalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4285F4).withValues(alpha: 0.7),
          const Color(0xFF4285F4).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

    final path = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..arcTo(rect, -120 * (3.14159 / 180), 60 * (3.14159 / 180), false)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}