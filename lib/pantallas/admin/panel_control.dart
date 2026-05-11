import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/pantallas/admin/gestion_estudiantes.dart';
import 'package:eco_poli/pantallas/admin/gestion_bares.dart';
import 'package:eco_poli/pantallas/admin/revision_solicitudes.dart'; 
import 'package:eco_poli/pantallas/admin/configuracion_puntos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaPanelControl extends StatefulWidget {
  const PantallaPanelControl({super.key});

  @override
  State<PantallaPanelControl> createState() => _PantallaPanelControlState();
}

class _PantallaPanelControlState extends State<PantallaPanelControl> {
  final _supabase = Supabase.instance.client;

  bool _estaCargando = true;
  int _totalEstudiantes = 0;
  int _totalBares = 0;
  int _solicitudesPendientes = 0;

  @override
  void initState() {
    super.initState();
    _verificarSeguridadYCargarDatos();
  }

  // ── LA BÓVEDA DE SEGURIDAD Y CARGA DE DATOS ──
  Future<void> _verificarSeguridadYCargarDatos() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) throw Exception('No hay sesión activa');

      // 1. Verificamos el rol (Asumiendo que tienes un campo 'rol' en tu tabla usuarios)
      final datosUsuario = await _supabase
          .from('usuarios')
          .select('rol') // Cambia 'rol' por el nombre exacto de tu columna si es distinto
          .eq('auth_id', authUser.id)
          .single();

      // Si no es el dueño, lo sacamos de la pantalla inmediatamente
      if (datosUsuario['rol'] != 'super_admin' && datosUsuario['rol'] != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso denegado: Área exclusiva de administración'), backgroundColor: Colors.red),
          );
          Navigator.pop(context); 
        }
        return;
      }

      // 2. Si pasó la seguridad, cargamos las métricas reales
      final estudiantes = await _supabase.from('usuarios').select('id_usuario');
      final bares = await _supabase.from('bares').select('id_bar');
      final solicitudes = await _supabase.from('solicitudes_bar').select('id_solicitud').eq('estado', 'pendiente');

      if (mounted) {
        setState(() {
          _totalEstudiantes = estudiantes.length;
          _totalBares = bares.length;
          _solicitudesPendientes = solicitudes.length;
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error en el panel: $e');
      if (mounted) {
        Navigator.pop(context); // Ante cualquier error raro, expulsamos por seguridad
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return Scaffold(
        backgroundColor: PaletaColores.background,
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: Column(
        children: [
          _encabezado(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _verificarSeguridadYCargarDatos,
              color: PaletaColores.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), 
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen General', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _tarjetaMetrica('Total\nEstudiantes', '$_totalEstudiantes', Icons.people_outline, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _tarjetaMetrica('Bares\nActivos', '$_totalBares', Icons.store_outlined, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _tarjetaMetrica('Nuevas\nSolicitudes', '$_solicitudesPendientes', Icons.mark_email_unread_outlined, Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Gestión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    _itemAccion(context, icono: Icons.settings_suggest_outlined, titulo: 'Configuración de Puntos', subtitulo: 'Definir el valor de cada botella reciclada', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaConfiguracionPuntos()))),
                    const SizedBox(height: 10),
                    _itemAccion(context, icono: Icons.fact_check_outlined, titulo: 'Revisar Solicitudes de Bar', subtitulo: 'Aprobar o rechazar nuevos locales', tieneAlerta: _solicitudesPendientes > 0, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRevisionSolicitudes()))),
                    const SizedBox(height: 10),
                    _itemAccion(context, icono: Icons.people, titulo: 'Gestión de Estudiantes', subtitulo: 'Administrar usuarios registrados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaGestionEstudiantes()))),
                    const SizedBox(height: 10),
                    _itemAccion(context, icono: Icons.store, titulo: 'Gestión de Bares', subtitulo: 'Administrar bares y encargados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaGestionBares()))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezado(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PaletaColores.primary, const Color(0xFF3B6D11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 24, 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Volver',
              ),
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel de Control', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Super Administrador', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaMetrica(String etiqueta, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _itemAccion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    bool tieneAlerta = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletaColores.fieldBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PaletaColores.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: PaletaColores.primary, size: 24),
                ),
                if (tieneAlerta)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)),
                  Text(subtitulo, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: PaletaColores.textSecondary),
          ],
        ),
      ),
    );
  }
}