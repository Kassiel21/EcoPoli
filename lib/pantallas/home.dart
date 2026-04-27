import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/servicios/autenticacion.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    final nombre = await _servicioAuth.obtenerNombreUsuario();
    setState(() => _nombre = nombre);
  }

  // ════════════════════════════════════════════════════════
  // UI
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos el SafeArea global para que el color verde del Header 
      // llegue hasta la barra de estado (donde está la hora y batería del celular)
      backgroundColor: PaletaColores.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // ── 1. HEADER FUSIONADO (Estilo PedidosYa) ─────────────
          _headerFusionado(),

          const SizedBox(height: 20),

          // ── 2. PUNTOS ACUMULADOS ─────────────────────────────────
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
                    '🪙 0 Puntos',
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

          // ──  GRID DE PRODUCTOS ─────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20), // Espacio al final al hacer scroll
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return _tarjetaProducto();
                },
              ),
            ),
          ),
        ],
      ),

      // ── BARRA INFERIOR ──────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: (index) => setState(() => _paginaActual = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PaletaColores.primary,
        unselectedItemColor: PaletaColores.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        iconSize: 28,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Retos'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Canjes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
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
      // SafeArea SOLO aquí adentro, para que proteja los textos de la cámara del celular
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
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        iconSize: 28,
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TEXTO DEL BANNER 
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

  // ── TARJETA DE PRODUCTO ──────────────────────────────────
  Widget _tarjetaProducto() {
    return Container(
      decoration: BoxDecoration(
        color: PaletaColores.fieldBackground, // Blanco o Gris super claro
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Imagen del producto 
          Container(
            width: 70, 
            height: 70,
            decoration: BoxDecoration(
              color: PaletaColores.textPrimary.withValues(alpha: 0.1),
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
              'Snack ESPOCH',
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
                    color: PaletaColores.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '25 puntos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: PaletaColores.primary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    debugPrint('Producto agregado al carrito');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PaletaColores.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart, 
                      color: Colors.white, 
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}