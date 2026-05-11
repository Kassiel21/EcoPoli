import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/pantallas/admin/historial_bar.dart';

class PantallaGestionBares extends StatefulWidget {
  const PantallaGestionBares({super.key});

  @override
  State<PantallaGestionBares> createState() => _PantallaGestionBaresState();
}

class _PantallaGestionBaresState extends State<PantallaGestionBares> {
  final _supabase = Supabase.instance.client;
  final _busquedaController = TextEditingController();
  
  bool _estaCargando = true;
  String _filtro = '';
  List<Map<String, dynamic>> _bares = [];

  @override
  void initState() {
    super.initState();
    _cargarBares();
  }

  // ── 1. LEER (READ): Traer bares y sus encargados ──
  Future<void> _cargarBares() async {
    setState(() => _estaCargando = true);
    try {
      final datos = await _supabase
          .from('bares')
          .select('id_bar, nombre, estado_bar, usuarios(nombre, apellido)')
          .order('fecha_creacion', ascending: false);

      if (mounted) {
        setState(() {
          _bares = List<Map<String, dynamic>>.from(datos);
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando bares: $e');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _baresFiltrados {
    if (_filtro.isEmpty) return _bares;
    return _bares.where((b) {
      final nombreBar = (b['nombre'] as String).toLowerCase();
      final encargado = '${b['usuarios']['nombre']} ${b['usuarios']['apellido']}'.toLowerCase();
      final termino = _filtro.toLowerCase();
      return nombreBar.contains(termino) || encargado.contains(termino);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Gestión de Bares', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _estaCargando
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // ── BUSCADOR ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _busquedaController,
                  onChanged: (v) => setState(() => _filtro = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar bar o encargado...',
                    prefixIcon: Icon(Icons.search, color: PaletaColores.primary),
                    filled: true,
                    fillColor: PaletaColores.fieldBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('${_baresFiltrados.length} locales registrados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── LISTA ──
              Expanded(
                child: _baresFiltrados.isEmpty 
                  ? Center(child: Text('No hay bares registrados', style: TextStyle(color: PaletaColores.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _cargarBares, // La función que llama a Supabase
                      color: PaletaColores.primary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(), // Obligatorio
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _baresFiltrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bar = _baresFiltrados[index];
                          return _tarjetaBar(bar);
                        },
                      ),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _tarjetaBar(Map<String, dynamic> bar) {
    final bool activo = bar['estado_bar'];
    final nombreEncargado = '${bar['usuarios']['nombre']} ${bar['usuarios']['apellido']}';

    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaHistorialBarAdmin(bar: bar),
          ),
        );
      },
      child:Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PaletaColores.fieldBackground,
          borderRadius: BorderRadius.circular(14),
        ),
      
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activo ? PaletaColores.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store, color: activo ? PaletaColores.primary : Colors.grey, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bar['nombre'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: activo ? PaletaColores.textPrimary : Colors.grey)),
                  Text('Admin: $nombreEncargado', style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activo ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activo ? 'Activo' : 'Cerrado/Suspendido',
                      style: TextStyle(fontSize: 11, color: activo ? Colors.green.shade700 : PaletaColores.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            //BOTON EDITAR
            IconButton(
              icon: Icon(Icons.edit_outlined, color: PaletaColores.primary, size: 20),
              onPressed: () => _mostrarDialogoEditar(context, bar),
              tooltip: 'Editar Bar',
            ),
            // ── BOTÓN DE SUSPENDER / ACTIVAR (SOFT DELETE) ──
            IconButton(
              icon: Icon(activo ? Icons.power_settings_new : Icons.power_settings_new, 
                        color: activo ? PaletaColores.error : Colors.green, size: 22),
              onPressed: () => _confirmarSuspension(context, bar),
              tooltip: activo ? 'Desactivar Bar' : 'Reactivar Bar',
            ),
          ],
        ),
      ), 
    );
  }

  // ── 2. ACTUALIZAR (SOFT DELETE) ──
  void _confirmarSuspension(BuildContext context, Map<String, dynamic> bar) {
    final nombreBar = bar['nombre'];
    final bool estaActivoActual = bar['estado_bar'];
    final idBar = bar['id_bar'];
    final accionTxt = estaActivoActual ? 'Desactivar' : 'Reactivar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$accionTxt bar'),
        content: Text('¿Estás seguro de $accionTxt "$nombreBar"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase
                    .from('bares')
                    .update({'estado_bar': !estaActivoActual}) // Cambia al estado contrario
                    .eq('id_bar', idBar);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estado de $nombreBar actualizado'), backgroundColor: PaletaColores.primary)
                );
                _cargarBares(); // Recargamos la lista
              } catch (e) {
                debugPrint('Error actualizando estado del bar: $e');
              }
            },
            child: Text(accionTxt, style: TextStyle(color: estaActivoActual ? PaletaColores.error : Colors.green)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, Map<String, dynamic> bar) {
    final nombreCtrl = TextEditingController(text: bar['nombre']);
    final correoNuevoDuenoCtrl = TextEditingController(); // Para buscar al nuevo dueño
    bool estaCargando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateHoja) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre del Bar', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              const Text('Cambiar Dueño (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: correoNuevoDuenoCtrl, 
                decoration: InputDecoration(
                  labelText: 'Correo del nuevo encargado', 
                  hintText: 'Dejar vacío para no cambiar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                )
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: estaCargando ? null : () async {
                    setStateHoja(() => estaCargando = true);
                    try {
                      String? idNuevoDueno;
                      
                      // 1. Si escribió un correo, buscamos a ese usuario
                      if (correoNuevoDuenoCtrl.text.trim().isNotEmpty) {
                        final resUser = await _supabase.from('usuarios').select('id_usuario').eq('correo', correoNuevoDuenoCtrl.text.trim()).maybeSingle();
                        if (resUser == null) {
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró al usuario con ese correo'), backgroundColor: Colors.red));
                          setStateHoja(() => estaCargando = false);
                          return;
                        }
                        idNuevoDueno = resUser['id_usuario'];
                        
                        // Opcional: Podrías actualizarle el rol a 'admin_bar' a este nuevo dueño
                        await _supabase.from('usuarios').update({'rol': 'admin_bar'}).eq('id_usuario', idNuevoDueno!);
                      }

                      // 2. Actualizamos el bar
                      final datosActualizar = {'nombre': nombreCtrl.text.trim()};
                      if (idNuevoDueno != null) datosActualizar['id_usuario'] = idNuevoDueno;

                      await _supabase.from('bares').update(datosActualizar).eq('id_bar', bar['id_bar']);
                      
                      if (mounted) {
                        Navigator.pop(ctx);
                        _cargarBares(); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bar actualizado correctamente'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      debugPrint('Error al editar bar: $e');
                    } finally {
                      setStateHoja(() => estaCargando = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white),
                  child: estaCargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}