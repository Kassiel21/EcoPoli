import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // para las fechas

class PantallaImpacto extends StatefulWidget {
  const PantallaImpacto({super.key});

  @override
  State<PantallaImpacto> createState() => _PantallaImpactoState();
}

class _PantallaImpactoState extends State<PantallaImpacto> {
  DateTime _fechaSeleccionada = DateTime.now();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _cargandoDatosIniciales = true;
  bool _cargandoActividades = false;
  int puntosActuales = 0;
  int botellasTotales = 0;
  List<Map<String, dynamic>> _actividades = [];

  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, cargamos los datos
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos () async {
    if (!mounted) return;
    setState(() {
      _cargandoDatosIniciales = true;
      _cargandoActividades = true;
    });

    try {
      final authId = _supabase.auth.currentUser!.id;    // Obtenemos el ID de usuario de la sesión activa 
      final datosUsuario = await _supabase      //OBTENER PUNTOS ACTUALES 
          .from('usuarios')
          .select('cant_puntos')
          .eq('auth_id', authId) // Buscamos por el auth_id vinculado
          .single();
      
      //BOTELLAS TOTALES 
      final userIdUuid = await _obtenerUuidUsuario(authId); // Necesitamos el id_usuario UUID
      
      if (userIdUuid != null) {
        final listaEntregasValidadas = await _supabase
            .from('entregas')
            .select('cantidad_botellas')
            .eq('id_usuario', userIdUuid)
            .eq('estado', 'validada'); 

        // Sumamos las botellas en memoria (Flutter)
        int sumaBotellas = 0;
        for (var entrega in listaEntregasValidadas) {
          sumaBotellas += (entrega['cantidad_botellas'] as int);
        }

        puntosActuales = datosUsuario['cant_puntos'] ?? 0;
        botellasTotales = sumaBotellas;

        // CARGAR ACTIVIDADES DEL DÍA 
        await _cargarActividadesDelDia(userIdUuid);
      }

    } catch (e) {
      debugPrint('❌ Error crítico cargando impacto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión con EcoPoli.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDatosIniciales = false;
          _cargandoActividades = false;
        });
      }
    }
  }

  // cargar actividades cuando cambia la fecha
  // ── SOLUCIÓN: FILTRO DE FECHAS EN EL LADO DEL CLIENTE ──
  Future<void> _cargarActividadesDelDia(String userIdUuid) async {
    try {
      // 1. Pedimos TODO el historial del estudiante (Supabase nos manda esto en milisegundos)
      final respuestaHistorial = await _supabase            
          .from('historial_puntos')
          .select()
          .eq('id_usuario', userIdUuid)
          .order('fecha_creacion', ascending: false); 

      List<Map<String, dynamic>> actividadesFormateadas = [];
      
      for (var registro in respuestaHistorial) {
        // 2. Supabase lo manda en Hora Universal (UTC). Aquí lo pasamos a la hora local exacta del celular.
        final fechaLocal = DateTime.parse(registro['fecha_creacion']).toLocal();
        
        // 3. Comparamos los días exactos en nuestra zona horaria
        if (fechaLocal.year == _fechaSeleccionada.year && 
            fechaLocal.month == _fechaSeleccionada.month && 
            fechaLocal.day == _fechaSeleccionada.day) {
            
          actividadesFormateadas.add({
            'hora': DateFormat('HH:mm').format(fechaLocal),
            'titulo': registro['puntos'] > 0 ? 'Puntos Ganados ⬆️' : 'Puntos Canjeados ⬇️',
            'descripcion': registro['descripcion'] ?? 'Actividad del día',
            'puntos': registro['puntos'], 
          });
        }
      }

      if (mounted) {
        setState(() {
          _actividades = actividadesFormateadas;
        });
      }

    } catch (e) {
      debugPrint('❌ Error cargando historial: $e');
    }
  }

  Future<String?> _obtenerUuidUsuario(String authId) async {
    try {
      final res = await _supabase.from('usuarios').select('id_usuario').eq('auth_id', authId).single();
      return res['id_usuario'];
    } catch (e) {
      return null;
    }
  }

  // Función para manejar el cambio de fecha 
  void _actualizarFechaYRecargar(DateTime nuevaFecha) async {
    if (!mounted) return;
    setState(() {
      _fechaSeleccionada = nuevaFecha;
      _cargandoActividades = true; // Solo mostramos carga en la línea de tiempo
    });

    final authId = _supabase.auth.currentUser!.id;
    final userIdUuid = await _obtenerUuidUsuario(authId);
    if (userIdUuid != null) {
      await _cargarActividadesDelDia(userIdUuid);
    }

    if (mounted) {
      setState(() => _cargandoActividades = false);
    }
  }

  // ── FUNCIÓN PARA ABRIR EL CALENDARIO COMPLETO ───────────────
  Future<void> _abrirCalendario() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2026), // El año en que empezó EcoPoli
      lastDate: DateTime.now(),  // No pueden ver el futuro
      //initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialEntryMode: DatePickerEntryMode.calendar,         // calendario normal, pero deja activo el botón para escribir a mano
      locale: const Locale('es', 'EC'),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PaletaColores.primary, // Color del encabezado y selección
              onPrimary: Colors.white,
              onSurface: PaletaColores.textPrimary,
            ),
            dividerTheme: const DividerThemeData(color: Colors.transparent),
            dividerColor: Colors.transparent,
          ),
          child: child!,
        );
      },
    );

    if (fechaElegida != null) {
      _actualizarFechaYRecargar(fechaElegida);
    }
  }

  Widget _construirSelectorDias() {
    List<DateTime> dias = List.generate(7, (index) => DateTime.now().subtract(Duration(days: 6 - index)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dias.map((dia) {
          bool esSeleccionado = dia.day == _fechaSeleccionada.day && dia.month == _fechaSeleccionada.month && 
          dia.year == _fechaSeleccionada.year;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!esSeleccionado) {
                  _actualizarFechaYRecargar(dia);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4), // Margen más pequeño
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: esSeleccionado ? PaletaColores.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (esSeleccionado)
                      BoxShadow(color: PaletaColores.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                    else
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
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
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dia.day}',
                      style: TextStyle(
                        color: esSeleccionado ? Colors.white : PaletaColores.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(), // Convertimos el map a una lista de widgets
      ),
    );
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
      body: _cargandoDatosIniciales 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                _construirHeroSection(),
                const SizedBox(height: 24),
                _construirSelectorDias(),
                const SizedBox(height: 20),
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
        FittedBox( // que números muy largos rompan el diseño
          fit: BoxFit.scaleDown,
          child: Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0))
        ),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  String _obtenerNombreDia(int weekday) {
    const dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return dias[weekday - 1];
  }

  //  LÍNEA DE TIEMPO (Timeline nativo)
  Widget _construirLineaTiempo() {
    return Expanded(
      child: _cargandoActividades
          ? const Center(child: CircularProgressIndicator()) // Carga de actividades
          : _actividades.isEmpty
              ? _construirEstadoVacio() // 👇 Estado Vacío que faltaba
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _actividades.length,
                  itemBuilder: (context, index) {
                    final actividad = _actividades[index];
                    final bool esUltimo = index == _actividades.length - 1;
                    
                    final bool esIngreso = actividad['puntos'] > 0;
                    // Usando rojo de error para egresos, verde para ingresos
                    final Color colorIcono = esIngreso ? Colors.green : Colors.redAccent; 
                    final IconData iconoPrincipal = esIngreso ? Icons.add_circle_outline : Icons.remove_circle_outline;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Columna izquierda (Línea de tiempo visual)
                          SizedBox(
                            width: 30,
                            child: Column(
                              children: [
                                Container(
                                  width: 16, height: 16,
                                  margin: const EdgeInsets.only(top: 14), 
                                  decoration: BoxDecoration(
                                    color: colorIcono, shape: BoxShape.circle,
                                    border: Border.all(color: PaletaColores.background, width: 3),
                                    boxShadow: [BoxShadow(color: colorIcono.withValues(alpha: 0.3), blurRadius: 4)]
                                  ),
                                ),
                                if (!esUltimo)
                                  Expanded(child: Container(width: 3, color: Colors.grey.shade300)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Tarjeta de contenido
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: colorIcono.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                      child: Icon(iconoPrincipal, color: colorIcono, size: 24),
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
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: PaletaColores.textPrimary),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                actividad['hora'],
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            actividad['descripcion'],
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${actividad['puntos'] > 0 ? '+' : ''}${actividad['puntos']}',
                                      style: TextStyle(color: colorIcono, fontWeight: FontWeight.w900, fontSize: 18),
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

  // para cuando no hay nada que mostrar
  Widget _construirEstadoVacio() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nature_people_outlined, size: 100, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        Text(
          'No hay actividad registrada.',
          style: TextStyle(color: PaletaColores.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}