import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaHistorialBarAdmin extends StatefulWidget {
  final Map<String, dynamic> bar;
  const PantallaHistorialBarAdmin({super.key, required this.bar});

  @override
  State<PantallaHistorialBarAdmin> createState() => _PantallaHistorialBarAdminState();
}

class _PantallaHistorialBarAdminState extends State<PantallaHistorialBarAdmin> {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = true; 
  int _totalBotellas = 0;
  int _totalCanjes = 0;

  @override
  void initState() {
    super.initState();
    _cargarMetricasBar();
  }

  Future<void> _cargarMetricasBar() async {
    setState(() => _estaCargando = true);
    try {
      final idBar = widget.bar['id_bar'];
      
      // Sumar botellas (Agregadas las llaves {} para solucionar el aviso del 'for')
      final resBotellas = await _supabase.from('entregas').select('cantidad_botellas').eq('id_bar', idBar);
      int suma = 0;
      for (var row in resBotellas) {
        suma += (row['cantidad_botellas'] as int);
      }

      // Contar canjes confirmados (Usando el método tradicional y seguro)
      final resCanjes = await _supabase.from('canjes').select('id_canje').eq('id_bar', idBar).eq('estado', 'confirmado');

      if (mounted) {
        setState(() {
          _totalBotellas = suma;
          _totalCanjes = resCanjes.length; // Error solucionado: Usamos la longitud de la lista
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error métricas bar: $e');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: Text(widget.bar['nombre']), 
        backgroundColor: PaletaColores.primary, 
        foregroundColor: Colors.white
      ),
      // Advertencia solucionada: Mostramos el círculo de carga mientras busca los datos
      body: _estaCargando 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _cargarMetricasBar,
            color: PaletaColores.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _tarjetaDato('Botellas Recolectadas', '$_totalBotellas', Icons.recycling, Colors.teal),
                  const SizedBox(height: 16),
                  _tarjetaDato('Canjes Entregados', '$_totalCanjes', Icons.shopping_bag_outlined, Colors.orange),
                  const SizedBox(height: 30),
                  
                ],
              ),
            ),
          ),
    );
  }

  Widget _tarjetaDato(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletaColores.fieldBackground, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 15)),
              Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}