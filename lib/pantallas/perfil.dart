import 'package:eco_poli/pantallas/historial_canjes.dart';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/servicios/autenticacion.dart';
import 'package:eco_poli/pantallas/admin/cambio_rol.dart';
import 'package:eco_poli/pantallas/admin/requisitos.dart';
import 'package:eco_poli/pantallas/admin/panel_control.dart';
import 'package:eco_poli/pantallas/login.dart';
import 'package:eco_poli/pantallas/perfil/cambiar_foto.dart';
import 'package:eco_poli/pantallas/perfil/cambiar_nombre.dart';
//import 'package:eco_poli/pantallas/perfil/ajustar_ubicacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/pantallas/admin_bar/retos_IA.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});
  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _servicioAuth = Autenticacion();
  String _nombre = '';
  String _correo = '';
  String? _urlFoto;
  int _puntos = 0;
  int _totalCanjes = 0;
  int _totalReciclado = 0;
  String _posicionRanking = '--';
  
  // 👇 DOS VARIABLES CLAVE
  String _rolBaseDatos = 'estudiante'; // Tus poderes reales
  bool _modoVistaEstudiante = false; // Tu interruptor visual

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuarioActual = _servicioAuth.usuarioActual;
    if (usuarioActual == null) return;

    try {
      final respuestaUser = await Supabase.instance.client
          .from('usuarios')
          .select('nombre, apellido, rol, cant_puntos, id_usuario, url_foto')
          .eq('auth_id', usuarioActual.id)
          .single();

      final idUsuarioInterno = respuestaUser['id_usuario'];
      final respuestaCanjes = await Supabase.instance.client.from('canjes').select('id_canje').eq('id_usuario', idUsuarioInterno);
      final respuestaReciclaje = await Supabase.instance.client.from('entregas').select('cantidad_botellas').eq('id_usuario', idUsuarioInterno);
      
      int sumaBotellas = 0;
      for (var item in respuestaReciclaje) sumaBotellas += (item['cantidad_botellas'] as int);

      final puntosActuales = respuestaUser['cant_puntos'] ?? 0;
      final respuestaRanking = await Supabase.instance.client.from('usuarios').select('id_usuario').gt('cant_puntos', puntosActuales);

      if (mounted) {
        setState(() {
          _nombre = '${respuestaUser['nombre']} ${respuestaUser['apellido']}';
          _correo = usuarioActual.email ?? '';
          _rolBaseDatos = respuestaUser['rol'] ?? 'estudiante';
          _urlFoto = respuestaUser['url_foto'];
          _puntos = puntosActuales;
          _totalCanjes = respuestaCanjes.length; 
          _totalReciclado = sumaBotellas;
          _posicionRanking = '#${respuestaRanking.length + 1}'; 
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar sesión', style: TextStyle(color: PaletaColores.error)),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await _servicioAuth.cerrarSesion();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PantallaLogin()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // rol mostrar a la pantalla
    final rolMostrado = _modoVistaEstudiante ? 'estudiante' : _rolBaseDatos;

    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: PaletaColores.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _encabezado(rolMostrado),
              const SizedBox(height: 16),
              _seccionResumen(),
              const SizedBox(height: 16),
              _seccionOpciones(rolMostrado),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _encabezado(String rolMostrado) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [PaletaColores.primary, const Color(0xFF3B6D11)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                backgroundImage: _urlFoto != null ? NetworkImage(_urlFoto!) : null,
                child: _urlFoto == null ? const Icon(Icons.person, size: 52, color: Colors.white) : null,
              ),
              const SizedBox(height: 10),
              Text(_nombre.isEmpty ? 'Usuario' : _nombre, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_correo, style: const TextStyle(fontSize: 17, color: Colors.white70)),
              
              if (rolMostrado == 'admin_bar')
                Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: PaletaColores.fieldBackground, borderRadius: BorderRadius.circular(12)), child: const Text('DUEÑO DE BAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87))),
              if (rolMostrado == 'super_admin' || rolMostrado == 'admin')
                Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)), child: const Text('SUPER ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionResumen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estadísticas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PaletaColores.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.emoji_events, 'Puntos', '$_puntos', Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.swap_horiz, 'Canjes', '$_totalCanjes', PaletaColores.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.recycling, 'Total reciclado', '$_totalReciclado', Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.leaderboard, 'Posición', _posicionRanking, Colors.deepPurple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaStat(IconData icono, String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.8))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icono, color: color, size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(etiqueta, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: PaletaColores.textSecondary)), Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))])),
        ],
      ),
    );
  }

  Widget _seccionOpciones(String rolMostrado) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (rolMostrado == 'admin_bar' || rolMostrado == 'super_admin') ...[
            _encabezadoSeccion('Gestión del Bar (Admin)'),
           _itemOpcion(Icons.smart_toy_rounded, 'Generar retos semanales', subtitulo: 'Crear 5 retos con Inteligencia Artificial', colorTexto: PaletaColores.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaGenerarRetosIA()))),
            const SizedBox(height: 16),
          ],

          _encabezadoSeccion('Información Personal'),
          _itemOpcion(Icons.person_outline, 'Mis canjes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaHistorial()))),
          _itemOpcion(Icons.person_outline, 'Cambiar nombre de usuario', onTap: () async {
            final huboCambio = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCambiarNombre()));
            if (huboCambio == true) _cargarDatos();
          }),
          //  URL_FOTO A LA SIGUIENTE PANTALLA
          _itemOpcion(Icons.photo_camera_outlined, 'Cambiar foto de perfil', onTap: () async {
            final huboCambio = await Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCambiarFoto(urlActual: _urlFoto)));
            if (huboCambio == true) _cargarDatos();
          }),
          const SizedBox(height: 16),

          _encabezadoSeccion('Ajustes de Sesión'),
          
          //MODO VISTA (Solo visible si tu rol en DB es super_admin o admin_bar)
          if (_rolBaseDatos == 'super_admin' || _rolBaseDatos == 'admin_bar')
            _itemOpcion(
              _modoVistaEstudiante ? Icons.visibility_off : Icons.visibility,
              _modoVistaEstudiante ? 'Salir de Vista Estudiante' : 'Ver como Estudiante',
              colorTexto: Colors.deepPurple,
              onTap: () {
                setState(() => _modoVistaEstudiante = !_modoVistaEstudiante);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_modoVistaEstudiante ? 'Modo Estudiante activado (Ocultando opciones admin)' : 'Modo Administrador restaurado')));
              }
            ),

          if (_rolBaseDatos == 'super_admin')
            _itemOpcion(Icons.swap_horiz, 'Cambiar rol', subtitulo: 'Herramienta administrativa', onTap: () async {
              final huboCambio = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCambioRol()));
              if (huboCambio == true) _cargarDatos();
            }),
          
          if (rolMostrado == 'estudiante')
            _itemOpcion(Icons.store_outlined, 'Solicitar ser Bar', subtitulo: 'Encargado del Bar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRequisitos()))),
          
          if (rolMostrado == 'super_admin' || rolMostrado == 'admin')
            _itemOpcion(Icons.admin_panel_settings_outlined, 'Panel de Control', subtitulo: 'Administración central', onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaPanelControl()));
              _cargarDatos(); // Recargar al volver
            }),
          
          const SizedBox(height: 8),
          const Divider(),
          _itemOpcion(Icons.logout, 'Cerrar Sesión', colorTexto: PaletaColores.error, onTap: _cerrarSesion),
        ],
      ),
    );
  }

  Widget _encabezadoSeccion(String titulo) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(titulo, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: PaletaColores.textPrimary)));
  }

  Widget _itemOpcion(IconData icono, String titulo, {String? subtitulo, Color? colorTexto, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: PaletaColores.fieldBackground, borderRadius: BorderRadius.circular(10)), child: Icon(icono, color: colorTexto ?? PaletaColores.primary, size: 20)),
      title: Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorTexto ?? PaletaColores.textPrimary)),
      subtitle: subtitulo != null ? Text(subtitulo, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)) : null,
      trailing: Icon(Icons.chevron_right, color: PaletaColores.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}