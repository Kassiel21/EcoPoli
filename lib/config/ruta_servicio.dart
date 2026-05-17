import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RutaServicio {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Obtiene una ruta real entre dos puntos usando la API pública de OSRM.
  /// Retorna un mapa con: puntos (List<LatLng>), distancia (metros), duracion (segundos) y pasos (List de instrucciones).
  /// Retorna null si hay error.
  Future<Map<String, dynamic>?> obtenerRutaOSRM(LatLng origen, LatLng destino) async {
    try {
      // OSRM usa formato: longitude,latitude
      // Agregamos &steps=true para obtener el paso a paso
      final url = Uri.parse(
        '$_osrmBaseUrl/route/v1/driving/'
        '${origen.longitude},${origen.latitude};'
        '${destino.longitude},${destino.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = route['distance'] as double?;
          final duration = route['duration'] as double?;
          
          List<Map<String, dynamic>> pasosProcesados = [];
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            if (leg['steps'] != null) {
              final steps = leg['steps'] as List;
              for (var step in steps) {
                if (step['maneuver'] != null && step['maneuver']['location'] != null) {
                  final loc = step['maneuver']['location'];
                  final latLng = LatLng(loc[1], loc[0]);
                  final instruccion = _traducirInstruccion(step);
                  pasosProcesados.add({
                    'instruccion': instruccion,
                    'coordenada': latLng,
                    'distancia': step['distance'] ?? 0,
                  });
                }
              }
            }
          }

          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            final puntos = coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
            
            return {
              'puntos': puntos,
              'distancia': distance?.toInt() ?? 0,
              'duracion': duration?.toInt() ?? 0,
              'pasos': pasosProcesados,
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Traduce e interpreta el tipo de maniobra de OSRM al español
  String _traducirInstruccion(Map<String, dynamic> step) {
    final maneuver = step['maneuver'];
    final type = maneuver['type'] ?? '';
    final modifier = maneuver['modifier'] ?? '';
    final name = (step['name'] != null && step['name'].toString().isNotEmpty) 
        ? step['name'] 
        : '';

    String destinoTexto = name.isNotEmpty ? 'hacia $name' : '';

    if (type == 'depart') {
      return name.isNotEmpty ? 'Dirígete hacia $name' : 'Inicia tu ruta';
    } else if (type == 'arrive') {
      return 'Has llegado a tu destino';
    } else if (type == 'turn') {
      if (modifier.contains('right')) {
        return 'Gira a la derecha $destinoTexto';
      } else if (modifier.contains('left')) {
        return 'Gira a la izquierda $destinoTexto';
      } else if (modifier == 'uturn') {
        return 'Da la vuelta en U $destinoTexto';
      }
      return 'Gira $destinoTexto';
    } else if (type == 'roundabout') {
      return 'En la rotonda, toma la salida $destinoTexto';
    } else if (type == 'continue') {
      return name.isNotEmpty ? 'Continúa por $name' : 'Sigue derecho';
    } else if (type == 'end of road') {
      if (modifier.contains('right')) {
        return 'Al final de la calle, gira a la derecha $destinoTexto';
      } else if (modifier.contains('left')) {
        return 'Al final de la calle, gira a la izquierda $destinoTexto';
      }
    } else if (type == 'fork') {
      if (modifier.contains('right')) {
        return 'Mantente a la derecha $destinoTexto';
      } else if (modifier.contains('left')) {
        return 'Mantente a la izquierda $destinoTexto';
      }
    }

    // Por defecto si no coincide
    return name.isNotEmpty ? 'Sigue por $name' : 'Sigue la ruta';
  }
}