import 'package:latlong2/latlong.dart';

class BarModelo {
  final String idBar;
  final String idUsuario;
  final String nombre;
  final String? descripcion;
  final LatLng coordenadas;
  final String? imagenBar;
  final bool estadoBar;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  BarModelo({
    required this.idBar,
    required this.idUsuario,
    required this.nombre,
    this.descripcion,
    required this.coordenadas,
    this.imagenBar,
    this.estadoBar = true,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory BarModelo.fromMap(Map<String, dynamic> map) {
    return BarModelo(
      idBar: map['id_bar'] as String,
      idUsuario: map['id_usuario'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      coordenadas: LatLng(
        (map['latitud'] as num).toDouble(),
        (map['longitud'] as num).toDouble(),
      ),
      imagenBar: map['imagen_bar'] as String?,
      estadoBar: map['estado_bar'] as bool? ?? true,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      fechaActualizacion: DateTime.parse(map['fecha_actualizacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_bar': idBar,
      'id_usuario': idUsuario,
      'nombre': nombre,
      'descripcion': descripcion,
      'latitud': coordenadas.latitude,
      'longitud': coordenadas.longitude,
      'imagen_bar': imagenBar,
      'estado_bar': estadoBar,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }
}