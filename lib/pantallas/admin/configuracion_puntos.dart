import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaConfiguracionPuntos extends StatefulWidget {
  const PantallaConfiguracionPuntos({super.key});

  @override
  State<PantallaConfiguracionPuntos> createState() => _PantallaConfiguracionPuntosState();
}

class _PantallaConfiguracionPuntosState extends State<PantallaConfiguracionPuntos> {
  final _supabase = Supabase.instance.client;
  final _puntosController = TextEditingController();
  final _motivoController = TextEditingController();
  
  bool _estaCargando = true;
  Map<String, dynamic>? _configActual;

  @override
  void initState() {
    super.initState();
    _obtenerConfiguracionActual();
  }

  Future<void> _obtenerConfiguracionActual() async {
    setState(() => _estaCargando = true);
    try {
      final data = await _supabase
          .from('configuracion_puntos')
          .select()
          .eq('vigente', true)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _configActual = data;
          _puntosController.text = data['puntos_por_botella'].toString();
        });
      }
    } catch (e) {
      debugPrint('Error al obtener config: $e');
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Future<void> _actualizarConfiguracion() async {
    final nuevosPuntos = int.tryParse(_puntosController.text);
    if (nuevosPuntos == null || nuevosPuntos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número válido de puntos'))
      );
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No hay sesión');

      // 👇 1. BUSCAMOS EL ID INTERNO DEL USUARIO
      final datosUsuario = await _supabase
          .from('usuarios')
          .select('id_usuario')
          .eq('auth_id', user.id)
          .single();
          
      final idUsuarioInterno = datosUsuario['id_usuario'];

      // 2. Desactivar la configuración vigente actual
      await _supabase
          .from('configuracion_puntos')
          .update({'vigente': false, 'fecha_fin': DateTime.now().toIso8601String()})
          .eq('vigente', true);

      // 👇 3. Insertar la nueva configuración usando el ID INTERNO
      await _supabase.from('configuracion_puntos').insert({
        'puntos_por_botella': nuevosPuntos,
        'motivo': _motivoController.text.trim(),
        'vigente': true,
        'configurado_por': idUsuarioInterno, // Corrección aplicada
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Métrica de puntos actualizada'), backgroundColor: Colors.green)
        );
        _motivoController.clear();
        _obtenerConfiguracionActual();
      }
    } catch (e) {
      debugPrint('Error al actualizar: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('Métricas de Puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary,
        foregroundColor: Colors.white,
      ),
      body: _estaCargando 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tarjetaInfoActual(),
                const SizedBox(height: 30),
                const Text('Actualizar Valor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _puntosController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Puntos por cada botella',
                    prefixIcon: const Icon(Icons.star_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _motivoController,
                  decoration: InputDecoration(
                    labelText: 'Motivo del cambio (Opcional)',
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _actualizarConfiguracion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PaletaColores.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Establecer nueva métrica', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _tarjetaInfoActual() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: PaletaColores.primary.withValues(alpha: 0.1),
            child: Icon(Icons.recycling, color: PaletaColores.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Valor vigente', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '${_configActual?['puntos_por_botella'] ?? 0} puntos',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('por cada botella de plástico', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}