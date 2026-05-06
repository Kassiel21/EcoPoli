/// Modelo que representa los datos del usuario en EcoPoli.
/// Mapea directamente la tabla `usuarios` de Supabase.
class UsuarioModelo {
  final String authId;
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;
  final String rol;
  final int cantPuntos;
  final bool estadoUsuario;
  final String? fotoPerfil; // URL en Supabase Storage (puede ser null)
  final String? ciudad;
  final String? direccion;

  const UsuarioModelo({
    required this.authId,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.rol,
    required this.cantPuntos,
    required this.estadoUsuario,
    this.fotoPerfil,
    this.ciudad,
    this.direccion,
  });

  /// Nombre completo del usuario
  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Construye un [UsuarioModelo] desde un mapa de Supabase
  factory UsuarioModelo.fromMap(Map<String, dynamic> map) {
    return UsuarioModelo(
      authId: map['auth_id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      cedula: map['cedula'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'estudiante',
      cantPuntos: map['cant_puntos'] as int? ?? 0,
      estadoUsuario: map['estado_usuario'] as bool? ?? true,
      fotoPerfil: map['foto_perfil'] as String?,
      ciudad: map['ciudad'] as String?,
      direccion: map['direccion'] as String?,
    );
  }

  /// Convierte el modelo a mapa para actualizar en Supabase
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'ciudad': ciudad,
      'direccion': direccion,
      'foto_perfil': fotoPerfil,
    };
  }

  /// Crea una copia del modelo con campos modificados
  UsuarioModelo copyWith({
    String? nombre,
    String? apellido,
    String? fotoPerfil,
    String? ciudad,
    String? direccion,
  }) {
    return UsuarioModelo(
      authId: authId,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula,
      correo: correo,
      rol: rol,
      cantPuntos: cantPuntos,
      estadoUsuario: estadoUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
    );
  }
}
