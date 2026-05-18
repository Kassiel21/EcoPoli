import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaCatalogoProductos extends StatefulWidget {
  const PantallaCatalogoProductos({super.key});

  @override
  State<PantallaCatalogoProductos> createState() => _PantallaCatalogoProductosState();
}

class _PantallaCatalogoProductosState extends State<PantallaCatalogoProductos> {
  final _supabase = Supabase.instance.client;
  bool _cargando = true;
  String? _miIdBar;
  List<Map<String, dynamic>> _productos = [];

  @override
  void initState() {
    super.initState();
    _inicializarCatalogo();
  }

  // ── 1. BUSCAR EL BAR DEL USUARIO Y SUS PRODUCTOS ──
  Future<void> _inicializarCatalogo() async {
    setState(() => _cargando = true);
    try {
      final miAuthId = _supabase.auth.currentUser!.id;
      final datosBarman = await _supabase.from('usuarios').select('id_usuario').eq('auth_id', miAuthId).single();
      final datosBar = await _supabase.from('bares').select('id_bar').eq('id_usuario', datosBarman['id_usuario']).maybeSingle();

      if (datosBar != null) {
        _miIdBar = datosBar['id_bar'];
        await _cargarProductos();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes un bar asignado.')));
      }
    } catch (e) {
      debugPrint('Error inicializando: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── 2. LEER PRODUCTOS DEL CATÁLOGO ──
  Future<void> _cargarProductos() async {
    if (_miIdBar == null) return;
    try {
      final res = await _supabase
          .from('productos')
          .select('*')
          .eq('id_bar', _miIdBar as Object)
          .eq('estado_prod', true) 
          .order('fecha_creacion', ascending: false);

      setState(() {
        _productos = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    }
  }

  // ── 3. ELIMINACIÓN LÓGICA (OCULTAR PRODUCTO) ──
  Future<void> _eliminarProducto(String idProducto) async {
    try {
      await _supabase.from('productos').update({'estado_prod': false}).eq('id_producto', idProducto);
      _cargarProductos();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Producto eliminado del catálogo')));
    } catch (e) {
      debugPrint('Error al eliminar: $e');
    }
  }

  // ── 4. FORMULARIO COMPLETO CON FOTO (BOTTOM SHEET) ──
  void _mostrarFormulario([Map<String, dynamic>? producto]) {
    final nombreCtrl = TextEditingController(text: producto?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: producto?['descripcion'] ?? '');
    final costoCtrl = TextEditingController(text: producto != null ? producto['puntos_costo'].toString() : '');
    final stockCtrl = TextEditingController(text: producto != null ? producto['stock'].toString() : '');
    
    File? imagenSeleccionada;
    String? urlImagenExistente = producto?['imagen_prod'];
    bool guardandoProducto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setModalState) {
          
          // FUNCIÓN INTERNA PARA ELEGIR FOTO
          Future<void> seleccionarFoto() async {
            final ImagePicker picker = ImagePicker();
            final XFile? foto = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (foto != null) {
              setModalState(() {
                imagenSeleccionada = File(foto.path);
              });
            }
          }

          // FUNCIÓN INTERNA  GUARDAR 
          Future<void> guardarEnBaseDatos() async {
            if (nombreCtrl.text.isEmpty || costoCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Llena los campos obligatorios')));
              return;
            }

            setModalState(() => guardandoProducto = true);

            try {
              String? urlFinalImagen = urlImagenExistente;

              // Si el usuario eligió una foto nueva, la subimos a Supabase Storage
              if (imagenSeleccionada != null) {
                final nombreArchivo = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
                final rutaStorage = 'snacks/$nombreArchivo';
                
                await _supabase.storage.from('productos_bar').upload(
                  rutaStorage,
                  imagenSeleccionada!,
                  fileOptions: const FileOptions(upsert: true),
                );
                urlFinalImagen = _supabase.storage.from('productos_bar').getPublicUrl(rutaStorage);
              }

              // Preparamos los datos
              final datosProducto = {
                'id_bar': _miIdBar,
                'nombre': nombreCtrl.text.trim(),
                'descripcion': descCtrl.text.trim(),
                'puntos_costo': int.parse(costoCtrl.text.trim()),
                'stock': int.parse(stockCtrl.text.trim()),
                if (urlFinalImagen != null) 'imagen_prod': urlFinalImagen,
              };

              if (producto == null) {
                await _supabase.from('productos').insert(datosProducto);
              } else {
                datosProducto['fecha_actualizacion'] = DateTime.now().toIso8601String();
                await _supabase.from('productos').update(datosProducto).eq('id_producto', producto['id_producto']);
              }

              if (mounted) {
                Navigator.pop(ctx);
                _cargarProductos();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Producto guardado con éxito'), backgroundColor: Colors.green));
              }
            } catch (e) {
              debugPrint('Error guardando: $e');
              setModalState(() => guardandoProducto = false);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
            }
          }

          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto == null ? 'Añadir al Menú' : 'Editar Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // ── ZONA DE LA FOTO ──
                  Center(
                    child: GestureDetector(
                      onTap: guardandoProducto ? null : seleccionarFoto,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          image: imagenSeleccionada != null
                              ? DecorationImage(image: FileImage(imagenSeleccionada!), fit: BoxFit.cover)
                              : urlImagenExistente != null && urlImagenExistente!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(urlImagenExistente!), fit: BoxFit.cover)
                                  : null,
                        ),
                        child: (imagenSeleccionada == null && (urlImagenExistente == null || urlImagenExistente!.isEmpty))
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.add_a_photo, color: Colors.grey, size: 30), SizedBox(height: 8), Text('Añadir foto', style: TextStyle(color: Colors.grey, fontSize: 12))],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── CAMPOS DE TEXTO ──
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Snack *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: costoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Puntos *', prefixIcon: Icon(Icons.star, color: Colors.amber), border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock *', prefixIcon: Icon(Icons.inventory_2_outlined), border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── BOTÓN DE GUARDAR ──
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: guardandoProducto ? null : guardarEnBaseDatos,
                      child: guardandoProducto 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Mi Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade400), const SizedBox(height: 16), const Text('Tu menú está vacío', style: TextStyle(fontSize: 18, color: Colors.grey))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final p = _productos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // FOTO DEL PRODUCTO EN LA LISTA
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 70, height: 70, color: Colors.grey.shade200,
                                child: p['imagen_prod'] != null && p['imagen_prod'].toString().isNotEmpty
                                    ? Image.network(p['imagen_prod'], fit: BoxFit.cover)
                                    : const Icon(Icons.fastfood, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // INFO DEL PRODUCTO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(p['descripcion'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)), child: Row(children: [const Icon(Icons.star, size: 12, color: Colors.amber), const SizedBox(width: 4), Text('${p['puntos_costo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))])),
                                      const SizedBox(width: 8),
                                      Text('Stock: ${p['stock']}', style: TextStyle(color: p['stock'] > 0 ? PaletaColores.primary: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // BOTONES EDITAR Y ELIMINAR
                            Column(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarFormulario(p), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarProducto(p['id_producto']), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: PaletaColores.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Añadir producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}