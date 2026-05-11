import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/pantallas/admin/historial_usuario.dart';

class PantallaGestionEstudiantes extends StatefulWidget {
  const PantallaGestionEstudiantes({super.key});

  @override
  State<PantallaGestionEstudiantes> createState() => _PantallaGestionEstudiantesState();
}

class _PantallaGestionEstudiantesState extends State<PantallaGestionEstudiantes> {
  final _supabase = Supabase.instance.client;
  final _busquedaController = TextEditingController();
  
  bool _estaCargando = true;
  String _filtro = '';
  List<Map<String, dynamic>> _estudiantes = [];

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _estaCargando = true);
    try {
      final datos = await _supabase
          .from('usuarios')
          .select('id_usuario, nombre, apellido, correo, rol, estado_usuario, url_foto')
          .order('fecha_creacion', ascending: false);

      if (mounted) {
        setState(() {
          _estudiantes = List<Map<String, dynamic>>.from(datos);
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _estudiantesFiltrados {
    if (_filtro.isEmpty) return _estudiantes;
    return _estudiantes.where((e) {
      final nombreCompleto = '${e['nombre']} ${e['apellido']}'.toLowerCase();
      final correo = (e['correo'] as String).toLowerCase();
      final termino = _filtro.toLowerCase();
      return nombreCompleto.contains(termino) || correo.contains(termino);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Gestión de Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _estaCargando 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _busquedaController,
                  onChanged: (v) => setState(() => _filtro = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    prefixIcon: Icon(Icons.search, color: PaletaColores.primary),
                    filled: true,
                    fillColor: PaletaColores.fieldBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('${_estudiantesFiltrados.length} usuarios registrados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── PULL TO REFRESH (DESLIZAR PARA RECARGAR) ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargarEstudiantes,
                  color: PaletaColores.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _estudiantesFiltrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _tarjetaEstudiante(_estudiantesFiltrados[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _tarjetaEstudiante(Map<String, dynamic> est) {
    final bool estaActivo = est['estado_usuario'];
    Color colorRol = Colors.blueGrey;
    if (est['rol'] == 'admin_bar') colorRol = Colors.orange;
    if (est['rol'] == 'super_admin') colorRol = Colors.redAccent;

    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaHistorialUsuarioAdmin(usuario: est),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PaletaColores.fieldBackground,
          borderRadius: BorderRadius.circular(14),
        ),
      
      
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: estaActivo ? colorRol.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.2),
              backgroundImage: est['url_foto'] != null ? NetworkImage(est['url_foto']) : null,
              child: est['url_foto'] == null 
                  ? Icon(Icons.person, color: estaActivo ? colorRol : Colors.grey, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${est['nombre']} ${est['apellido']}', 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: estaActivo ? PaletaColores.textPrimary : Colors.grey)),
                  Text(est['correo'], style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(est['rol'].toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorRol)),
                      if (!estaActivo) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('SUSPENDIDO', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ],
              ),
            ),
            // Botón Editar
            IconButton(
              icon: Icon(Icons.edit_outlined, color: PaletaColores.primary, size: 20),
              onPressed: () => _mostrarDialogoEditar(context, est),
              tooltip: 'Editar',
            ),
            // Botón Suspender
            IconButton(
              icon: Icon(estaActivo ? Icons.block : Icons.check_circle_outline, color: estaActivo ? PaletaColores.error : Colors.green, size: 20),
              onPressed: () => _confirmarSuspension(context, est),
              tooltip: estaActivo ? 'Suspender' : 'Reactivar',
            ),
          ],
        ),
      ),
    );
  }

  // ── FUNCIÓN EDITAR (UPDATE) ──
  void _mostrarDialogoEditar(BuildContext context, Map<String, dynamic> est) {
    final nombreCtrl = TextEditingController(text: est['nombre']);
    final apellidoCtrl = TextEditingController(text: est['apellido']);
    String rolSeleccionado = est['rol'];

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
              const Text('Editar Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: apellidoCtrl, decoration: InputDecoration(labelText: 'Apellido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              const Text('Rol del sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              DropdownButton<String>(
                value: rolSeleccionado,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                  DropdownMenuItem(value: 'admin_bar', child: Text('Dueño de Bar')),
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Administrador')),
                ],
                onChanged: (val) {
                  if (val != null) setStateHoja(() => rolSeleccionado = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _supabase.from('usuarios').update({
                        'nombre': nombreCtrl.text.trim(),
                        'apellido': apellidoCtrl.text.trim(),
                        'rol': rolSeleccionado,
                      }).eq('id_usuario', est['id_usuario']);
                      
                      _cargarEstudiantes(); 
                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado'), backgroundColor: Colors.green));
                    } catch (e) {
                      debugPrint('Error al editar: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white),
                  child: const Text('Guardar Cambios'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarSuspension(BuildContext context, Map<String, dynamic> estudiante) {
    final nombreCompleto = '${estudiante['nombre']} ${estudiante['apellido']}';
    final bool estaActivoActual = estudiante['estado_usuario'];
    final idUsuario = estudiante['id_usuario'];
    final accionTxt = estaActivoActual ? 'Suspender' : 'Reactivar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$accionTxt estudiante'),
        content: Text('¿Estás seguro de $accionTxt el acceso a $nombreCompleto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase.from('usuarios').update({'estado_usuario': !estaActivoActual}).eq('id_usuario', idUsuario);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estado actualizado'), backgroundColor: PaletaColores.primary));
                _cargarEstudiantes();
              } catch (e) {
                debugPrint('Error actualizando estado: $e');
              }
            },
            child: Text(accionTxt, style: TextStyle(color: estaActivoActual ? PaletaColores.error : Colors.green)),
          ),
        ],
      ),
    );
  }
}