import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/pantallas/ticket.dart';
import 'package:eco_poli/config/supabase.dart';

class PantallaCarrito extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final int puntosUsuario;

  const PantallaCarrito({
    super.key,
    required this.carrito,
    required this.puntosUsuario,
  });

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  int totalPuntos = 0;

  @override
  void initState() {
    super.initState();
    _calcularTotal();
  }

  void _calcularTotal() {
    int suma = 0;
    for (var item in widget.carrito) {
      final costo = item['puntos_costo'] as int? ?? 0;
      final cantidad = item['cantidad'] as int? ?? 1;
      suma += (costo * cantidad);
    }
    setState(() {
      totalPuntos = suma;
    });
  }
  
  //  Incrementar cantidad
  void _incrementarCantidad(int index) {
    setState(() {
      widget.carrito[index]['cantidad'] = (widget.carrito[index]['cantidad'] ?? 1) + 1;
      _calcularTotal();
    });
  }

  // Decrementar cantidad
  void _decrementarCantidad(int index) {
    setState(() {
      if (widget.carrito[index]['cantidad'] > 1) {
        widget.carrito[index]['cantidad']--;
      } else {
        widget.carrito.removeAt(index); // Si llega a cero, se borra
      }
      _calcularTotal();
    });
  }

  // ✍️ Ingresar cantidad manualmente con teclado
  void _ingresarCantidadManual(int index) {
    final TextEditingController controlador = TextEditingController(
      text: widget.carrito[index]['cantidad'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresa la cantidad'),
          content: TextField(
            controller: controlador,
            keyboardType: TextInputType.number, // Abre el teclado numérico
            decoration: const InputDecoration(hintText: 'Ej: 5'),
            autofocus: true, // Abre el teclado automáticamente
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cierra sin guardar
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final valor = controlador.text.trim();
                if (valor.isNotEmpty) {
                  final nuevaCant = int.tryParse(valor);
                  if (nuevaCant != null) {
                    setState(() {
                      if (nuevaCant <= 0) {
                        _eliminarProducto(index); // Si pone 0, se elimina
                      } else {
                        widget.carrito[index]['cantidad'] = nuevaCant;
                        _calcularTotal();
                      }
                    });
                  }
                }
                Navigator.pop(context); // Cierra la ventana emergente
              },
              child: Text('Guardar', style: TextStyle(color: PaletaColores.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🗑️ Eliminar producto por completo
  void _eliminarProducto(int index) {
    setState(() {
      widget.carrito.removeAt(index);
      _calcularTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool puedeCanjear = widget.puntosUsuario >= totalPuntos;

    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.background,
        elevation: 0,
        foregroundColor: PaletaColores.textPrimary,
      ),
      body: Column(
        children: [
          // Lista de productos
          Expanded(
            child: widget.carrito.isEmpty
            ? const Center(child: Text('No hay productos en tu carrito.'))
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: widget.carrito.length,
                itemBuilder: (context, index) {
                  final item = widget.carrito[index];
                  final cant = item['cantidad'] ?? 1;
                  final subtotal = (item['puntos_costo'] ?? 0) * cant;
                  return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16), // Un poco más de espacio interior
                        decoration: BoxDecoration(
                          color: PaletaColores.fieldBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Alinea la imagen arriba
                          children: [
                            // 1. IMAGEN DEL PRODUCTO (Izquierda)
                            CircleAvatar(
                              radius: 25, // Un poquito más grande
                              backgroundColor: PaletaColores.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.fastfood, color: PaletaColores.primary, size: 28),
                            ),
                            const SizedBox(width: 16),

                            // 2. BLOQUE DERECHO (Textos, Basurero y Controles)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  // FILA SUPERIOR: Nombre y Basurero
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['nombre'] ?? 'Producto',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Basurero en la esquina superior derecha
                                      GestureDetector(
                                        onTap: () => _eliminarProducto(index),
                                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 17),
                                      ),
                                    ],
                                  ),
                                  
                                  //const SizedBox(height: 5), // Separación vertical

                                  // FILA INFERIOR: Puntos y Selector de Cantidad
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Puntos (Izquierda)
                                      Text(
                                        '$subtotal puntos', 
                                        style: const TextStyle(
                                          color: PaletaColores.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      
                                      // Selector de Cantidad en la esquina inferior derecha
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _decrementarCantidad(index),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(Icons.remove, size: 10, color: Colors.grey),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _ingresarCantidadManual(index),
                                              child: Container(
                                                color: Colors.transparent, 
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                                child: Text(
                                                  '$cant', 
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _incrementarCantidad(index),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(Icons.add, size: 10, color: PaletaColores.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                  },
                ),
          ),

          //Resumen inferior
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a descontar:', style: TextStyle(fontSize: 18)),
                      Text(
                        '$totalPuntos puntos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: puedeCanjear ? PaletaColores.primary : PaletaColores.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tus puntos:', style: TextStyle(color: Colors.grey)),
                      Text('${widget.puntosUsuario} puntos', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PaletaColores.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: (puedeCanjear && widget.carrito.isNotEmpty)
                        ? () async {
                            try {
                              // 1. Obtener el auth_id del usuario conectado
                              final authId = SupabaseConfig.client.auth.currentUser?.id;
                              if (authId == null) return;

                              // 2. Obtener el id_usuario (UUID) de tu tabla usuarios
                              final usuarioData = await SupabaseConfig.client
                                  .from('usuarios')
                                  .select('id_usuario')
                                  .eq('auth_id', authId)
                                  .single();
                              final idUsuario = usuarioData['id_usuario'];

                              // 3. Obtener un id_bar (Tomaremos el primero que exista para probar)
                              final barData = await SupabaseConfig.client
                                  .from('bares')
                                  .select('id_bar')
                                  .limit(1)
                                  .single();
                              final idBar = barData['id_bar'];

                              // 4. INSERTAR EN LA TABLA CANJES
                              // No enviamos 'codigo_seguridad' porque tu base lo genera solo
                              final nuevoCanje = await SupabaseConfig.client.from('canjes').insert({
                                'id_usuario': idUsuario,
                                'id_bar': idBar,
                                'puntos_usados': totalPuntos,
                                'estado': 'pendiente',
                              }).select('id_canje,codigo_seguridad').single();

                              final String idCanjeGenerado = nuevoCanje['id_canje'];
                              final String codigoDeLaBase = nuevoCanje['codigo_seguridad'];

                              // 5. RESTAR LOS PUNTOS EN LA TABLA USUARIOS
                              final listaDetalles = widget.carrito.map((item) {
                                return {
                                  'id_canje': idCanjeGenerado, // El ID del ticket que acabamos de crear
                                  'id_producto': item['id_producto'], // ⚠️ Asegúrate de que el producto traiga su id desde el Home
                                  'cantidad': item['cantidad'],
                                  'puntos_unitarios': item['puntos_costo'],
                                };
                              }).toList();

                              // Guardamos todos los productos de golpe
                              await SupabaseConfig.client.from('canje_prod').insert(listaDetalles);

                              // 6. RESTAR LOS PUNTOS AL USUARIO
                              final nuevosPuntos = widget.puntosUsuario - totalPuntos;
                              await SupabaseConfig.client
                                  .from('usuarios')
                                  .update({'cant_puntos': nuevosPuntos})
                                  .eq('id_usuario', idUsuario);

                              // 7. Limpiar y navegar al Ticket visual
                              final copiaProductos = List<Map<String, dynamic>>.from(widget.carrito);
                              widget.carrito.clear();

                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaTicket(
                                    codigoVerificacion: codigoDeLaBase,
                                    productos: copiaProductos,
                                    totalPuntos: totalPuntos,
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint('Error en el proceso de canje: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al procesar el canje: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        : null,
                      child: Text(
                        puedeCanjear ? 'GENERAR CÓDIGO' : 'PUNTOS INSUFICIENTES',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}