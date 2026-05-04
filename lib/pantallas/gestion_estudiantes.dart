import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaGestionEstudiantes extends StatefulWidget {
  const PantallaGestionEstudiantes({super.key});

  @override
  State<PantallaGestionEstudiantes> createState() => _PantallaGestionEstudiantesState();
}

class _PantallaGestionEstudiantesState extends State<PantallaGestionEstudiantes> {
  final _busquedaController = TextEditingController();
  String _filtro = '';

  // Datos de ejemplo — reemplazar con llamada a Supabase
  final List<Map<String, String>> _estudiantes = [
    {'nombre': 'Ana García', 'correo': 'ana@espoch.edu.ec', 'rol': 'Estudiante'},
    {'nombre': 'Luis Pérez', 'correo': 'luis@espoch.edu.ec', 'rol': 'Estudiante'},
    {'nombre': 'María Torres', 'correo': 'maria@espoch.edu.ec', 'rol': 'Estudiante'},
    {'nombre': 'Carlos Ruiz', 'correo': 'carlos@espoch.edu.ec', 'rol': 'Estudiante'},
    {'nombre': 'Sofía Mora', 'correo': 'sofia@espoch.edu.ec', 'rol': 'Estudiante'},
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _estudiantesFiltrados {
    if (_filtro.isEmpty) return _estudiantes;
    return _estudiantes
        .where((e) =>
            e['nombre']!.toLowerCase().contains(_filtro.toLowerCase()) ||
            e['correo']!.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
        title: const Text('Gestión de Estudiantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── BUSCADOR ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (v) => setState(() => _filtro = v),
              decoration: InputDecoration(
                hintText: 'Buscar estudiante...',
                prefixIcon: Icon(Icons.search, color: PaletaColores.primary),
                filled: true,
                fillColor: PaletaColores.fieldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── ENCABEZADO TABLA ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_estudiantesFiltrados.length} estudiantes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── LISTA ─────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _estudiantesFiltrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final est = _estudiantesFiltrados[index];
                return _tarjetaEstudiante(est);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAgregar(context),
        backgroundColor: PaletaColores.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _tarjetaEstudiante(Map<String, String> est) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletaColores.fieldBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: PaletaColores.primary.withValues(alpha: 0.15),
            child: Icon(Icons.person, color: PaletaColores.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(est['nombre']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
                Text(est['correo']!, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: PaletaColores.primary, size: 20),
            onPressed: () {},
            tooltip: 'Editar',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: PaletaColores.error, size: 20),
            onPressed: () => _confirmarEliminar(context, est['nombre']!),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agregar Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary)),
            const SizedBox(height: 16),
            _campoBusqueda('Nombre completo', Icons.person_outline),
            const SizedBox(height: 12),
            _campoBusqueda('Correo institucional', Icons.email_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _campoBusqueda(String hint, IconData icono) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icono, color: PaletaColores.primary),
        filled: true,
        fillColor: PaletaColores.fieldBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar estudiante'),
        content: Text('¿Eliminar a $nombre?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Eliminar', style: TextStyle(color: PaletaColores.error)),
          ),
        ],
      ),
    );
  }
}
