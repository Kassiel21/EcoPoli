import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaMapaSelector extends StatefulWidget {
  const PantallaMapaSelector({super.key});

  @override
  State<PantallaMapaSelector> createState() => _PantallaMapaSelectorState();
}

class _PantallaMapaSelectorState extends State<PantallaMapaSelector> {
  final MapController _mapController = MapController();
  
  // Coordenadas aproximadas de la ESPOCH para que inicie ahí
  LatLng _centroActual = const LatLng(-1.6586, -78.6775);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubica tu bar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          //  EL MAPA INTERACTIVO DE OPENSTREETMAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroActual,
              initialZoom: 16.0,
              // Cada vez que el usuario mueve el mapa, actualizamos las coordenadas
              onPositionChanged: (posicion, tieneGesto) {
                if (posicion.center != null) {
                  setState(() => _centroActual = posicion.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecopoli.app',
              ),
            ],
          ),
          // PANEL FLOTANTE DE COORDENADAS
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ubicación Actual', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_centroActual.latitude.toStringAsFixed(5)}\nLng: ${_centroActual.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: PaletaColores.primary),
                  ),
                ],
              ),
            ),
          ),
          // EL PIN CENTRAL (Siempre se queda en el medio de la pantalla)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Ajuste visual para que la punta toque el centro
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),
          
          //  BOTÓN DE CONFIRMACIÓN
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PaletaColores.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
              onPressed: () {
                // Al presionar, cerramos esta pantalla y "devolvemos" las coordenadas
                Navigator.pop(context, _centroActual);
              },
              child: const Text('Confirmar Ubicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}