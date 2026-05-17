import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Datos de navegación procesados
class NavigationData {
  final LatLng position;
  final double heading;
  final double speed;
  final bool isSnapped;
  final double deviationFromRoute;
  
  NavigationData({
    required this.position,
    required this.heading,
    required this.speed,
    this.isSnapped = false,
    this.deviationFromRoute = 0.0,
  });
}

/// Motor de navegación inteligente tipo Waze/Google Maps Pro.
/// Responsable de filtrar GPS, suavizar movimiento, calcular desviaciones
/// y decidir re-routing. Separado completamente de la UI.
class NavigationEngine {
  // Configuración de filtrado GPS
  static const double _minDistanceThreshold = 3.0; // metros
  static const double _maxDistanceThreshold = 100.0; // metros (anti-spoofing)
  static const double _smoothingFactor = 0.3; // factor de suavizado (0-1)
  
  // Configuración de snap to road
  static const double _snapDistance = 15.0; // metros
  static const double _deviationThreshold = 20.0; // metros para re-routing
  
  // Estado interno
  LatLng? _lastValidPosition;
  LatLng? _lastFilteredPosition;
  DateTime? _lastPositionTime;
  
  // Ruta actual para snap to road
  List<LatLng>? _currentRoute;
  
  // Stream de posición filtrada
  final _filteredPositionController = StreamController<NavigationData>.broadcast();
  
  Stream<NavigationData> get filteredPositionStream => _filteredPositionController.stream;
  
  /// Establece la ruta actual para snap to road
  void setRoute(List<LatLng> route) {
    _currentRoute = route;
  }
  
  /// Limpia la ruta actual
  void clearRoute() {
    _currentRoute = null;
  }
  
  /// Procesa una nueva posición GPS cruda
  void processRawPosition(LatLng rawPosition, double heading, DateTime timestamp) {
    // 1. Validación básica (anti-spoofing)
    if (_lastValidPosition != null) {
      final distance = _calculateDistance(_lastValidPosition!, rawPosition);
      if (distance > _maxDistanceThreshold) {
        // Posición inválida (salto demasiado grande)
        return;
      }
    }
    
    // 2. Filtrado anti-jitter (low pass filter)
    final filteredPosition = _applyLowPassFilter(rawPosition);
    
    // 3. Cálculo de velocidad
    final speed = _calculateSpeed(filteredPosition, timestamp);
    
    // 4. Predicción de movimiento
    final predictedPosition = _predictMovement(filteredPosition, heading, speed);
    
    // 5. Snap to road si hay ruta activa
    final snappedPosition = _snapToRoad(predictedPosition);
    final deviation = _calculateDeviationFromRoute(predictedPosition);
    
    // 6. Actualizar estado interno
    _lastValidPosition = rawPosition;
    _lastFilteredPosition = filteredPosition;
    _lastPositionTime = timestamp;
    
    // 7. Emitir posición procesada
    final navigationData = NavigationData(
      position: snappedPosition,
      heading: heading,
      speed: speed,
      isSnapped: _currentRoute != null,
      deviationFromRoute: deviation,
    );
    
    _filteredPositionController.add(navigationData);
  }
  
  /// Aplica filtro low-pass para suavizar posición
  LatLng _applyLowPassFilter(LatLng rawPosition) {
    if (_lastFilteredPosition == null) {
      return rawPosition;
    }
    
    final distance = _calculateDistance(_lastFilteredPosition!, rawPosition);
    
    // Si el movimiento es menor al umbral, ignorar (anti-jitter)
    if (distance < _minDistanceThreshold) {
      return _lastFilteredPosition!;
    }
    
    // Interpolación lineal suave
    final lat = _lastFilteredPosition!.latitude + 
        (rawPosition.latitude - _lastFilteredPosition!.latitude) * _smoothingFactor;
    final lng = _lastFilteredPosition!.longitude + 
        (rawPosition.longitude - _lastFilteredPosition!.longitude) * _smoothingFactor;
    
    return LatLng(lat, lng);
  }
  
  /// Calcula la velocidad actual en m/s
  double _calculateSpeed(LatLng position, DateTime timestamp) {
    if (_lastFilteredPosition == null || _lastPositionTime == null) {
      return 0.0;
    }
    
    final distance = _calculateDistance(_lastFilteredPosition!, position);
    final timeDelta = timestamp.difference(_lastPositionTime!).inMilliseconds / 1000.0;
    
    if (timeDelta <= 0) {
      return 0.0;
    }
    
    return distance / timeDelta;
  }
  
  /// Predice la posición futura basada en heading y velocidad
  LatLng _predictMovement(LatLng position, double heading, double speed) {
    if (speed < 0.5) {
      return position; // No predecir si está casi detenido
    }
    
    // Predecir 500ms en el futuro
    final predictionTime = 0.5; // segundos
    final predictionDistance = speed * predictionTime;
    
    // Convertir heading a radianes
    final headingRad = heading * pi / 180.0;
    
    // Calcular desplazamiento
    final earthRadius = 6371000.0; // metros
    final latRad = position.latitude * pi / 180.0;
    final lngRad = position.longitude * pi / 180.0;
    
    final dLat = (predictionDistance * cos(headingRad)) / earthRadius;
    final dLng = (predictionDistance * sin(headingRad)) / (earthRadius * cos(latRad));
    
    final predictedLat = (latRad + dLat) * 180.0 / pi;
    final predictedLng = (lngRad + dLng) * 180.0 / pi;
    
    return LatLng(predictedLat, predictedLng);
  }
  
  /// Alinea la posición a la ruta más cercana (snap to road)
  LatLng _snapToRoad(LatLng position) {
    if (_currentRoute == null || _currentRoute!.isEmpty) {
      return position;
    }
    
    LatLng? closestPoint;
    double minDistance = double.infinity;
    
    for (final point in _currentRoute!) {
      final distance = _calculateDistance(position, point);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }
    
    // Si está cerca de la ruta, alinear
    if (closestPoint != null && minDistance < _snapDistance) {
      return closestPoint;
    }
    
    return position;
  }
  
  /// Calcula la desviación de la ruta actual
  double _calculateDeviationFromRoute(LatLng position) {
    if (_currentRoute == null || _currentRoute!.isEmpty) {
      return 0.0;
    }
    
    double minDistance = double.infinity;
    
    for (final point in _currentRoute!) {
      final distance = _calculateDistance(position, point);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }
  
  /// Decide si es necesario recalcular la ruta
  bool shouldRecalculateRoute() {
    if (_lastFilteredPosition == null || _currentRoute == null) {
      return false;
    }
    
    final deviation = _calculateDeviationFromRoute(_lastFilteredPosition!);
    
    // Recalcular si la desviación es significativa
    return deviation > _deviationThreshold;
  }
  
  /// Calcula la distancia entre dos puntos en metros
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
  
  /// Limpia recursos
  void dispose() {
    _filteredPositionController.close();
  }
}