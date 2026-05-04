import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaGestionBares extends StatefulWidget {
  const PantallaGestionBares({super.key});

  @override
  State<PantallaGestionBares> createState() => _PantallaGestionBaresState();
}

class _PantallaGestionBaresState extends State<PantallaGestionBares> {
  final _busquedaController = TextEditingController();
  String _filtro = '';

  // Datos de ejemplo — reemplazar con llamada a Supabase
  final List<Map<String, String>> _bares = [
    {'nombre': 'Bar Central', 'encargado': 'Pedro Alvarado', 'estado': 'Activo'},
    {'nombre': 'Bar Norte', 'encargado': 'Lucía Vega', 'estado': 'Activo'},
    {'nombre': 'Bar Sur', 'encargado': 'Roberto Díaz', 'estado': 'Inactivo'},
    {'nombre': 'Bar Facultad', 'encargado': 'Carmen López', 'estado': 'Activo'},
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _baresFiltrados {
    if (_filtro.isEmpty) return _bares;
    return _bares
        .where((b) =>
            b['nombre']!.toLowerCase().contains(_filtro.toLowerCase()) ||
            b['encargado']!.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();
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
      body: Column(
        children: [
          // ── BUSCADOR ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (v) => setState(() => _filtro = v),
              decoration: InputDecoration(
                hintText: 'Buscar bar...',
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_baresFiltrados.length} bares registrados',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── LISTA ─────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _baresFiltrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bar = _baresFiltrados[index];
                return _tarjetaBar(bar);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAgregar(context),
        backgroundColor: PaletaColores.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar Bar', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _tarjetaBar(Map<String, String> bar) {
    final activo = bar['estado'] == 'Activo';
    return Container(
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
              color: PaletaColores.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.store, color: PaletaColores.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bar['nombre']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
                Text(bar['encargado']!, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: activo ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bar['estado']!,
                    style: TextStyle(fontSize: 11, color: activo ? Colors.green.shade700 : PaletaColores.error, fontWeight: FontWeight.w600),
                  ),
                ),
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
            onPressed: () => _confirmarEliminar(context, bar['nombre']!),
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
            Text('Agregar Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary)),
            const SizedBox(height: 16),
            _campo('Nombre del bar', Icons.store_outlined),
            const SizedBox(height: 12),
            _campo('Encargado', Icons.person_outline),
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

  Widget _campo(String hint, IconData icono) {
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
        title: const Text('Eliminar bar'),
        content: Text('¿Eliminar "$nombre"?'),
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
