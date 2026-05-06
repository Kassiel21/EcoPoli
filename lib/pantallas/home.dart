import 'package:eco_poli/pantallas/perfil.dart';
import 'package:eco_poli/pantallas/retos_ranking.dart';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/servicios/autenticacion.dart';
import 'package:eco_poli/config/supabase.dart';
import 'package:eco_poli/pantallas/carrito.dart';
import 'package:eco_poli/pantallas/notificaciones.dart';
import 'package:eco_poli/pantallas/mi_impacto.dart';

class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

class _PantallaHomeState extends State<PantallaHome> {
  // ── ESTADO ───────────────────────────────────────────────
  final _servicioAuth = Autenticacion();
  String _nombre = '';
  int _paginaActual = 0;
  int _puntos = 0; 
  List<dynamic> _productos = []; 
  List<dynamic> _productosFiltrados = [];
  List<Map<String, dynamic>> _carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarNombre();
    _cargarProductos();
  }

  Future<void> _cargarNombre() async {
    final nombre = await _servicioAuth.obtenerNombreUsuario();
    int puntosObtenidos = 0;

    try {
      final authId = SupabaseConfig.client.auth.currentUser?.id;
      if (authId != null) {
        final datos = await SupabaseConfig.client
            .from('usuarios')
            .select('cant_puntos')
            .eq('auth_id', authId)
            .single();
        puntosObtenidos = datos['cant_puntos'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error obteniendo puntos: $e');
    }

    setState(() {
      _nombre = nombre;
      _puntos = puntosObtenidos;
    });
  }

  Future<void> _cargarProductos() async {
    try {
      // Traemos todos los productos de la base
      final lista = await SupabaseConfig.client
      .from('productos').select('id_producto, nombre, descripcion, puntos_costo, stock');
      
      setState(() {
        _productos = lista;
        _productosFiltrados = lista; // Al inicio mostramos todos
      });
    } catch (e) {
      debugPrint('Error obteniendo productos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el catálogo')),
      );
    }
  }

  //Función para el Pull-to-Refresh
  Future<void> _refrescarPantalla() async {
    // Future.wait ejecuta ambas tareas al mismo tiempo para que sea más rápido
    await Future.wait([
      _cargarNombre(),    // Recarga los puntos
      _cargarProductos(), // Recarga el catálogo
    ]);
  }

  void _buscarProducto(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((prod) {
          final nombreProd = prod['nombre'].toString().toLowerCase(); 
          return nombreProd.contains(texto.toLowerCase());
        }).toList();
      }
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto, {int cantidad=1}) {
    setState(() {
      //buscamos si el producto ya está en el carrito usando su nombre
      int index = _carrito.indexWhere((item) => item['nombre'] == producto['nombre']);
      if (index != -1) {
        // Si YA EXISTE
        _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + cantidad;
      } else {
        // Si NO EXISTE, 
        Map<String, dynamic> nuevoItem = Map<String, dynamic>.from(producto);
        nuevoItem['cantidad'] = cantidad;
        _carrito.add(nuevoItem);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} añadido a tu carrito'),
        backgroundColor: PaletaColores.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // suma las cantidades reales de todo el carrito
  int _obtenerTotalItemsCarrito() {
    int total = 0;
    for (var item in _carrito) {
      total += (item['cantidad'] as int? ?? 1);
    }
    return total;
  }

  // UI
  
  Widget _vistaHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER FUSIONADO 
        _headerFusionado(),
        const SizedBox(height: 20),

        // PUNTOS ACUMULADOS 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: PaletaColores.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PaletaColores.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🪙 $_puntos Puntos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PaletaColores.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // GRID DE PRODUCTOS 
        Expanded(
          child: RefreshIndicator(
            color: PaletaColores.primary,
            backgroundColor: Colors.white,
            onRefresh: _refrescarPantalla,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20), 
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final productoActual = _productosFiltrados[index];
                  return _tarjetaProducto(productoActual);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //  arreglo con todas las pantallas del menú inferior
    final List<Widget> pantallasDelMenu = [
      _vistaHome(),                                    // Índice 0: Icono Home
      const Center(child: Text('📍 Bares (Próximamente)')),     // Índice 1: Icono Ubicación
      const PantallaImpacto(),                                  // Índice 2: Icono Calendario (¡NUEVA!)
      const PantallaRetos(),      // Índice 3: Icono Trofeo
      const PantallaPerfil()    // Índice 4: Icono Persona
    ];

    return Scaffold(
      backgroundColor: PaletaColores.background,
      // body cambia según el botón presionado
      body: pantallasDelMenu[_paginaActual], 

      // BARRA INFERIOR 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: (index) => setState(() => _paginaActual = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PaletaColores.primary,
        unselectedItemColor: PaletaColores.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        iconSize: 28,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  // MÉTODOS DE UI 
  // ════════════════════════════════════════════════════════

  // ── HEADER 
  Widget _headerFusionado() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // gradiente verde 
        gradient: LinearGradient(
          colors: [PaletaColores.primary, const Color(0xFF3B6D11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: PaletaColores.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      // SafeArea 
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //ÍCONOS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '¡Hola, $_nombre! 👋',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Blanco para resaltar en el fondo verde
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        iconSize: 28,
                        icon: Badge(
                          // Solo se muestra si el total es mayor a 0
                          isLabelVisible: _obtenerTotalItemsCarrito() > 0, 
                          label: Text(
                            // Mostramos el total real sumado
                            '${_obtenerTotalItemsCarrito()}', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: PaletaColores.error,
                          child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PantallaCarrito(
                                carrito: _carrito,
                                puntosUsuario: _puntos,
                              ),
                            ),
                          ).then((_) {
                            _cargarNombre(); 
                            setState(() {}); 
                          });
                        },
                      ),

                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PantallaNotificaciones(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TEXTO DEL BANNER 23
              const Text(
                '¿Sabías qué?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Una botella de PET tarda hasta 500 años en degradarse en la naturaleza.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70 // Un blanco ligeramente opaco
                ),
              ),
              const SizedBox(height: 24),

              //  BUSCADOR 
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco puro para contrastar
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: _buscarProducto,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                      child: Icon(Icons.search,
                          color: PaletaColores.primary, size: 26),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ── MOSTRAR DETALLE DEL PRODUCTO (panel inferior) ─────────
  void _mostrarDetalleProducto(Map<String, dynamic> producto) {
    final nombreProducto = producto['nombre'] ?? 'Producto sin nombre';
    final precioPuntos = producto['puntos_costo'] ?? 0;
    final descripcion = producto['descripcion'] ?? 'Delicioso producto disponible en el bar de tu facultad.';

    // 1. Declaramos el controlador y la cantidad ANTES del modal
    int cantidadSeleccionada = 1;
    final controladorCantidad = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal suba con el teclado
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            return Padding(
              // 👇 ESTO ES MAGIA: Empuja el modal hacia arriba cuando sale el teclado
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PaletaColores.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50, height: 5,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Imagen
                    Center(
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: PaletaColores.textPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fastfood_outlined, size: 60, color: PaletaColores.primary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título y Puntos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nombreProducto,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: PaletaColores.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$precioPuntos puntos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PaletaColores.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PaletaColores.textSecondary)),
                    const SizedBox(height: 8),
                    Text(descripcion, style: TextStyle(fontSize: 15, color: PaletaColores.textPrimary, height: 1.5)),
                    const SizedBox(height: 24),

                    //  SELECTOR DE CANTIDAD (Con texto manual)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cantidad:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              // Botón Menos
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.grey),
                                onPressed: () {
                                  if (cantidadSeleccionada > 1) {
                                    setStateModal(() {
                                      cantidadSeleccionada--;
                                      controladorCantidad.text = cantidadSeleccionada.toString();
                                    });
                                  }
                                },
                              ),
                              
                              // CAJA DE TEXTO MANUAL
                              SizedBox(
                                width: 50,
                                child: TextField(
                                  controller: controladorCantidad,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none, // Sin borde porque ya lo tiene el contenedor
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (valorEscrito) {
                                    if (valorEscrito.isEmpty) return;
                                    int? nuevaCantidad = int.tryParse(valorEscrito);
                                    if (nuevaCantidad != null && nuevaCantidad > 0) {
                                      setStateModal(() {
                                        cantidadSeleccionada = nuevaCantidad;
                                      });
                                    } else {
                                      setStateModal(() {
                                        cantidadSeleccionada = 1;
                                        controladorCantidad.text = '1';
                                      });
                                    }
                                  },
                                ),
                              ),

                              // Botón Más
                              IconButton(
                                icon: Icon(Icons.add, color: PaletaColores.primary),
                                onPressed: () {
                                  setStateModal(() {
                                    cantidadSeleccionada++;
                                    controladorCantidad.text = cantidadSeleccionada.toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón principal
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Me imagino que aquí usas tu función _agregarAlCarrito original
                           _agregarAlCarrito(producto, cantidad: cantidadSeleccionada);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaletaColores.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Añadir al Carrito',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // ── TARJETA DE PRODUCTO ──────────────────────────────────
  Widget _tarjetaProducto(Map<String,dynamic>producto){
    final nombreProducto = producto['nombre'] ?? 'Producto';
    final precioPuntos = producto['puntos_costo'] ?? 0;
    final int stock = producto['stock'] ?? 0;
    final bool agotado = stock <= 0;

    return GestureDetector(
      onTap: (){
        if(!agotado){
          _mostrarDetalleProducto(producto);
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este producto está agotado'), behavior: SnackBarBehavior.floating),
          );
        }
        debugPrint('👆 Hice clic en la tarjeta de: $nombreProducto');
      },
      child: Container(
        decoration: BoxDecoration(
          color:agotado? Colors.grey.shade200:PaletaColores.fieldBackground, // Blanco o Gris super claro
          borderRadius: BorderRadius.circular(20),
          // Si está agotado
          boxShadow: agotado?[]:[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children:[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen del producto 
                Container(
                  width: 70, 
                  height: 70,
                  decoration: BoxDecoration(
                    color: agotado ? Colors.grey.shade400 : PaletaColores.textPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle, 
                  ),
                  child: Icon(
                    Icons.fastfood_outlined, 
                    color: PaletaColores.textPrimary,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 12),
                // Título del producto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    nombreProducto,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: PaletaColores.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
                const SizedBox(height: 12),

                // Fila: Puntos + Botón
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: agotado ? Colors.grey.shade300 : PaletaColores.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$precioPuntos puntos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: agotado ? Colors.grey : PaletaColores.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: agotado ? Colors.grey.shade400 : PaletaColores.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          agotado ? Icons.block : Icons.add_shopping_cart,
                          color: Colors.white, size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            //Etiqueta roja de AGOTADO
            if (agotado)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                  child: const Text('AGOTADO', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}