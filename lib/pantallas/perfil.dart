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
import 'package:eco_poli/pantallas/perfil/ajustar_ubicacion.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _servicioAuth = Autenticacion();
  String _nombre = '';
  String _correo = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final nombre = await _servicioAuth.obtenerNombreUsuario();
    setState(() {
      _nombre = nombre;
      _correo = _servicioAuth.usuarioActual?.email ?? '';
    });
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER CON AVATAR ──────────────────────────
            _encabezado(),

            const SizedBox(height: 16),

            // ── SECCIÓN: RESUMEN ───────────────────────────
            _seccionResumen(),

            const SizedBox(height: 16),

            // ── SECCIÓN: INFORMACIÓN PERSONAL ─────────────
            _seccionOpciones(),

            const SizedBox(height: 32),
          ],
        ),
      ),
      //bottomNavigationBar: _barraNavegacion(),
    );
  }

  // ── ENCABEZADO ─────────────────────────────────────────
  Widget _encabezado() {
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: const Icon(Icons.person, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // Nombre
              Text(
                _nombre.isEmpty ? 'Usuario' : _nombre,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Correo
              Text(
                _correo,
                style: const TextStyle(fontSize: 17, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── RESUMEN DE ESTADÍSTICAS ────────────────────────────
  Widget _seccionResumen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PaletaColores.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.emoji_events, 'Puntos', '200', Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.swap_horiz, 'Canjes', '4', PaletaColores.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.recycling, 'Total reciclado', '4', Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.leaderboard, 'Posición', '#34', Colors.deepPurple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaStat(IconData icono, String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: PaletaColores.textSecondary)),
                Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN OPCIONES ───────────────────────────────────
  Widget _seccionOpciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información Personal
          _encabezadoSeccion('Información Personal'),
          _itemOpcion(Icons.person_outline, 'Mis canjes',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaHistorial()))),
          _itemOpcion(Icons.person_outline, 'Cambiar nombre de usuario',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCambiarNombre()))),
          _itemOpcion(Icons.photo_camera_outlined, 'Cambiar foto de perfil',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCambiarFoto()))),
          const SizedBox(height: 16),

          // Configuración General
          _encabezadoSeccion('Configuración General'),
          _itemOpcion(Icons.location_on_outlined, 'Ajustar Ubicación',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaAjustarUbicacion()))),
          const SizedBox(height: 16),

          // Ajustes de Sesión
          _encabezadoSeccion('Ajustes de Sesión'),
          _itemOpcion(Icons.swap_horiz, 'Cambiar de rol',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCambioRol()))),
          _itemOpcion(Icons.store_outlined, 'Solicitar ser Bar',
              subtitulo: 'Encargado del Bar',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRequisitos()))),
          _itemOpcion(Icons.admin_panel_settings_outlined, 'Administrador',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaPanelControl()))),
          const SizedBox(height: 8),
          const Divider(),
          _itemOpcion(Icons.logout, 'Cerrar Sesión', colorTexto: PaletaColores.error, onTap: _cerrarSesion),
        ],
      ),
    );
  }

  Widget _encabezadoSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          color: PaletaColores.textPrimary,
        ),
      ),
    );
  }

  Widget _itemOpcion(
    IconData icono,
    String titulo, {
    String? subtitulo,
    Color? colorTexto,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: PaletaColores.fieldBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: colorTexto ?? PaletaColores.primary, size: 20),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorTexto ?? PaletaColores.textPrimary,
        ),
      ),
      subtitle: subtitulo != null
          ? Text(subtitulo, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary))
          : null,
      trailing: Icon(Icons.chevron_right, color: PaletaColores.textSecondary, size: 20),
      onTap: onTap,
    );
  }

}
