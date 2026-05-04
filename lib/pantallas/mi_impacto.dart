import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
//import 'package:intl/intl.dart'; // para las fechas

class PantallaImpacto extends StatefulWidget {
  const PantallaImpacto({super.key});

  @override
  State<PantallaImpacto> createState() => _PantallaImpactoState();
}

class _PantallaImpactoState extends State<PantallaImpacto> {
  DateTime _fechaSeleccionada = DateTime.now();

  // ──  DISEÑO ─────────────────────────────────
  final int puntosActuales = 850;
  final int botellasTotales = 142;

  //  actividades del día seleccionado
  final List<Map<String, dynamic>> _actividades = [
    {
      'hora': '14:30',
      'titulo': 'Jugo del Valle Canjeado',
      'descripcion': 'Bar de la Facultad de Informática (FIE)',
      'puntos': -50,
      'tipo': 'canje',
    },
    {
      'hora': '10:15',
      'titulo': 'Reciclaje Aprobado',
      'descripcion': 'Entregaste 5 botellas PET',
      'puntos': 25,
      'tipo': 'reciclaje',
    },
    {
      'hora': '08:00',
      'titulo': 'Bono Diario',
      'descripcion': '¡Ingresaste a la app hoy!',
      'puntos': 5,
      'tipo': 'bono',
    },
  ];

  // ── FUNCIÓN PARA ABRIR EL CALENDARIO COMPLETO ───────────────
  Future<void> _abrirCalendario() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2026), // El año en que empezó EcoPoli
      lastDate: DateTime.now(),  // No pueden ver el futuro
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PaletaColores.primary, // Color del encabezado y selección
              onPrimary: Colors.white,
              onSurface: PaletaColores.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaElegida != null) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
      // Aquí, en el futuro, llamarás a Supabase para bajar las actividades de este día exacto.
    }
  }

  // ── UI ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Mi Impacto ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, size: 28),
            tooltip: 'Buscar por fecha',
            onPressed: _abrirCalendario,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _construirHeroSection(),
          const SizedBox(height: 15),
          _construirSelectorDias(),
          const SizedBox(height: 5),
          _construirLineaTiempo(),
        ],
      ),
    );
  }

  // SECCIÓN DE LOGROS (Hero)
  Widget _construirHeroSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10, top: 1),
      decoration: BoxDecoration(
        color: PaletaColores.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: PaletaColores.primary.withValues(alpha: 0.3),blurRadius: 15,offset: const Offset(0,5))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _tarjetaEstadistica('PUNTOS', '$puntosActuales', Icons.stars_rounded)),
          Container(height: 60, width: 3, color: Colors.white.withValues(alpha: 0.6)),
          Expanded(child: _tarjetaEstadistica('BOTELLAS RECICLADAS', '$botellasTotales', Icons.recycling_rounded)),
        ],
      ),
    );
  }

  Widget _tarjetaEstadistica(String titulo, String valor, IconData icono) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 12),
        Text(valor, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  //  CINTA SEMANAL (Selector de días)
  Widget _construirSelectorDias() {
    // Generamos los últimos 7 días
    List<DateTime> dias = List.generate(7, (index) => DateTime.now().subtract(Duration(days: 6 - index)));

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        itemBuilder: (context, index) {
          DateTime dia = dias[index];
          bool esSeleccionado = dia.day == _fechaSeleccionada.day && 
          dia.month == _fechaSeleccionada.month && dia.year == _fechaSeleccionada.year;

          return GestureDetector(
            onTap: () => setState(() => _fechaSeleccionada = dia),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 65,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: esSeleccionado ? PaletaColores.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (esSeleccionado)
                    BoxShadow(color: PaletaColores.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                  else 
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _obtenerNombreDia(dia.weekday),
                    style: TextStyle(
                      color: esSeleccionado ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dia.day}',
                    style: TextStyle(
                      color: esSeleccionado ? Colors.white : PaletaColores.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _obtenerNombreDia(int weekday) {
    const dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return dias[weekday - 1];
  }

  //  LÍNEA DE TIEMPO (Timeline nativo)
  Widget _construirLineaTiempo() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _actividades.length,
        itemBuilder: (context, index) {
          final actividad = _actividades[index];
          final bool esUltimo = index == _actividades.length - 1;
          
          final bool esIngreso = actividad['puntos'] > 0;
          final Color colorIcono = esIngreso ? Colors.green : PaletaColores.error;
          final IconData iconoPrincipal = esIngreso ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Columna izquierda (Punto y Línea)
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 14), // Alinea el punto con el texto
                        decoration: BoxDecoration(
                          color: colorIcono,
                          shape: BoxShape.circle,
                          border: Border.all(color: PaletaColores.background, width: 3),
                          boxShadow: [
                            BoxShadow(color: colorIcono.withValues(alpha: 0.4), blurRadius: 4)
                          ]
                        ),
                      ),
                      if (!esUltimo)
                        Expanded(
                          child: Container(
                            width: 3,
                            color: Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Columna derecha (Tarjeta de contenido)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colorIcono.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                            child: Icon(iconoPrincipal, color: colorIcono),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        actividad['titulo'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      actividad['hora'],
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  actividad['descripcion'],
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${actividad['puntos'] > 0 ? '+' : ''}${actividad['puntos']}',
                            style: TextStyle(
                              color: colorIcono,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}