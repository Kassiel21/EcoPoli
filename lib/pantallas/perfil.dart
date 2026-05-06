import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:eco_poli/modelos/usuario_modelo.dart';
import 'package:eco_poli/repositorios/perfil_repositorio.dart';
import 'package:eco_poli/servicios/autenticacion.dart';
import 'package:eco_poli/widgets/perfil/avatar_perfil_widget.dart';
import 'package:eco_poli/pantallas/admin/cambio_rol.dart';
import 'package:eco_poli/pantallas/admin/requisitos.dart';
import 'package:eco_poli/pantallas/admin/panel_control.dart';
import 'package:eco_poli/pantallas/login.dart';
import 'package:eco_poli/pantallas/perfil/cambiar_foto.dart';
import 'package:eco_poli/pantallas/perfil/cambiar_nombre.dart';
import 'package:eco_poli/pantallas/perfil/ajustar_ubicacion.dart';
import 'package:eco_poli/pantallas/historial_canjes.dart';

/// Pantalla principal del perfil del usuario.
/// Muestra el encabezado con avatar, resumen de estadísticas y opciones de configuración.
/// Usa [PerfilRepositorio] para cargar los datos del usuario desde Supabase.
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _repositorio = PerfilRepositorio();
  final _servicioAuth = Autenticacion();

  UsuarioModelo? _usuario;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga el perfil completo del usuario desde Supabase
  Future<void> _cargarDatos() async {
    try {
      final usuario = await _repositorio.obtenerPerfil();
      if (mounted) setState(() { _usuario = usuario; _cargando = false; });
    } catch (e) {
      debugPrint('❌ Error cargando perfil: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Navega a una sub-pantalla y recarga el perfil al volver
  Future<void> _recargarAlVolver(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    _cargarDatos();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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
    return _cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                _encabezado(),
                const SizedBox(height: 16),
                _seccionResumen(),
                const SizedBox(height: 16),
                _seccionOpciones(),
                const SizedBox(height: 32),
              ],
            ),
          );
  }

  // ── ENCABEZADO ───────────────────────────────────────────────────────────────

  Widget _encabezado() {
    final nombre = _usuario?.nombre ?? 'Usuario';
    final correo = _servicioAuth.usuarioActual?.email ?? '';

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
              AvatarPerfilWidget(
                urlFoto: _usuario?.fotoPerfil,
                radio: 48,
              ),
              const SizedBox(height: 12),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correo,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── RESUMEN DE ESTADÍSTICAS ──────────────────────────────────────────────────

  Widget _seccionResumen() {
    final puntos = _usuario?.cantPuntos ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PaletaColores.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.emoji_events, 'Tus Puntos', '$puntos', Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.swap_horiz, 'Canjeados', '0', PaletaColores.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tarjetaStat(Icons.recycling, 'Botellas\nRecicladas', '0', Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _tarjetaStat(Icons.leaderboard, 'Tu Posición', '#--', Colors.deepPurple)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: TextStyle(fontSize: 12, color: PaletaColores.textSecondary)),
                Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN OPCIONES ─────────────────────────────────────────────────────────

  Widget _seccionOpciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información Personal
          _encabezadoSeccion('Información Personal'),
          _itemOpcion(
            Icons.person_outline,
            'Cambiar nombre de usuario',
            onTap: () => _recargarAlVolver(const PantallaCambiarNombre()),
          ),
          _itemOpcion(
            Icons.photo_camera_outlined,
            'Cambiar foto de perfil',
            onTap: () => _recargarAlVolver(const PantallaCambiarFoto()),
          ),
          _itemOpcion(
            Icons.receipt_long_outlined,
            'Mis Canjes',
            subtitulo: 'Historial de canjes realizados',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaHistorial()),
            ),
          ),
          const SizedBox(height: 16),

          // Configuración General
          _encabezadoSeccion('Configuración General'),
          _itemOpcion(
            Icons.location_on_outlined,
            'Ajustar Ubicación',
            onTap: () => _recargarAlVolver(const PantallaAjustarUbicacion()),
          ),
          const SizedBox(height: 16),

          // Ajustes de Sesión
          _encabezadoSeccion('Ajustes de Sesión'),
          _itemOpcion(
            Icons.swap_horiz,
            'Cambiar de rol',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaCambioRol()),
            ),
          ),
          _itemOpcion(
            Icons.store_outlined,
            'Solicitar ser Bar',
            subtitulo: 'Encargado del Bar',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaRequisitos()),
            ),
          ),
          _itemOpcion(
            Icons.admin_panel_settings_outlined,
            'Administrador',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaPanelControl()),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          _itemOpcion(
            Icons.logout,
            'Cerrar Sesión',
            colorTexto: PaletaColores.error,
            onTap: _cerrarSesion,
          ),
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
          fontSize: 15,
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
