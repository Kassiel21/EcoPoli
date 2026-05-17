import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UbicacionServicio {
  Future<bool> solicitarPermisos() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw 'El servicio de ubicación (GPS) está apagado en tu teléfono.';
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado.';
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw 'Permisos de ubicación denegados permanentemente. Ve a ajustes.';
    }

    return true;
  }

  Future<Position?> obtenerUbicacionActual() async {
    await solicitarPermisos(); // Si falla, lanzará excepción

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      throw 'Error al obtener la coordenada exacta: $e';
    }
  }

  /// Retorna un stream de ubicación en tiempo real.
  /// Actualiza la posición cada vez que el usuario se mueve más de la distancia mínima especificada.
  Stream<Position> obtenerUbicacionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros de movimiento
      ),
    );
  }

  /// Obtiene una dirección aproximada usando la API de Nominatim (OpenStreetMap)
  Future<String?> obtenerDireccion(LatLng ubicacion) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${ubicacion.latitude}&lon=${ubicacion.longitude}&zoom=18&addressdetails=1',
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'EcoPoliApp/1.0', // Es buena práctica enviar un User-Agent a Nominatim
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['address'] != null) {
          final address = data['address'];
          final road = address['road'] ?? address['pedestrian'] ?? '';
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
          final city = address['city'] ?? address['town'] ?? '';
          
          List<String> parts = [];
          if (road.isNotEmpty) parts.add(road);
          if (suburb.isNotEmpty) parts.add(suburb);
          if (parts.isEmpty && city.isNotEmpty) parts.add(city);
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          return data['display_name']?.split(',').first ?? 'Ubicación seleccionada';
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Busca lugares usando la API de Nominatim
  Future<List<Map<String, dynamic>>> buscarLugares(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'EcoPoliApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'nombre': item['display_name']?.split(',').first ?? 'Lugar',
          'descripcion': item['display_name'] ?? '',
          'coordenadas': LatLng(
            double.parse(item['lat']),
            double.parse(item['lon']),
          ),
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}