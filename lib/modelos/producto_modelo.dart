class ProductoModelo {
  final String id;
  final String nombre;
  final String descripcion;
  final int puntosCosto;
  final int stock;

  ProductoModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntosCosto,
    required this.stock,
  });

  factory ProductoModelo.fromMap(Map<String, dynamic> map) {
    return ProductoModelo(
      id: map['id_producto']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      puntosCosto: map['puntos_costo'] is int 
          ? map['puntos_costo'] as int 
          : int.tryParse(map['puntos_costo']?.toString() ?? '0') ?? 0,
      stock: map['stock'] is int 
          ? map['stock'] as int 
          : int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_producto': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'puntos_costo': puntosCosto,
      'stock': stock,
    };
  }

  bool get disponible => stock > 0;
}