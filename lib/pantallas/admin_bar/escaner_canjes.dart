import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eco_poli/config/paleta_colores.dart';

class PantallaEscanerCanjes extends StatefulWidget {
  const PantallaEscanerCanjes({super.key});

  @override
  State<PantallaEscanerCanjes> createState() => _PantallaEscanerCanjesState();
}

class _PantallaEscanerCanjesState extends State<PantallaEscanerCanjes> {
  final _supabase = Supabase.instance.client;
  bool _procesando = false;
  final MobileScannerController _scannerController = MobileScannerController();

  // ── LECTURA DEL CÓDIGO (CÁMARA) ──
  Future<void> _alDetectarCodigo(BarcodeCapture captura) async {
    // Seguro lógico: Ignora lecturas si ya está procesando uno
    if (_procesando) return; 
    
    final List<Barcode> codigos = captura.barcodes;
    if (codigos.isEmpty || codigos.first.rawValue == null) return;

    final String codigoEscaneado = codigos.first.rawValue!;
    
    setState(() => _procesando = true);
    // ❌ Se eliminó el .pause() para evitar congelamientos en Android

    await _validarCanjeEnBaseDatos(codigoEscaneado);
  }

  // ── INGRESO MANUAL DE CÓDIGO ──
  void _mostrarDialogoManual() {
    final codigoCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ingresar código ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: codigoCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Ejemplo: ECO-X7Y8',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.keyboard),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PaletaColores.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (codigoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _procesando = true);
              _validarCanjeEnBaseDatos(codigoCtrl.text.trim());
            },
            child: const Text('Validar Ticket'),
          ),
        ],
      ),
    );
  }

  
  // ── VALIDACIÓN EN SUPABASE (CON CADUCIDAD DE 24H) ──
  Future<void> _validarCanjeEnBaseDatos(String codigo) async {
    try {
      final canje = await _supabase
          .from('canjes')
          .select('*, usuarios(nombre, apellido), canje_prod(cantidad, productos(nombre))')
          .eq('codigo_seguridad', codigo)
          .maybeSingle();

      if (!mounted) return;

      if (canje == null) {
        _mostrarAlertaError('Código no válido o inexistente.');
        return;
      }

      final estado = canje['estado'];

      //  24 HORAS 
      final fechaExpiracion = DateTime.parse(canje['fecha_expiracion']);
      final horaActual = DateTime.now();

      if (estado == 'pendiente' && horaActual.isAfter(fechaExpiracion)) {
        await _supabase.from('canjes').update({'estado': 'expirado'}).eq('id_canje', canje['id_canje']);
        _mostrarAlertaError('Este ticket caducó. Expiró el: ${fechaExpiracion.toLocal().toString().split('.')[0]}');
        return;
      }

      if (estado == 'confirmado') {
        _mostrarAlertaError('Este ticket ya fue entregado anteriormente.');
        return;
      }
      
      if (estado == 'expirado' || estado == 'cancelado') {
        _mostrarAlertaError('Este ticket está $estado y ya no es válido.');
        return;
      }

      _mostrarResumenPedido(canje);

    } catch (e) {
      debugPrint('Error leyendo QR: $e');
      _mostrarAlertaError('Error de conexión al validar el código.');
    }
  }

  // ── MOSTRAR PEDIDO Y CONFIRMAR ──
  void _mostrarResumenPedido(Map<String, dynamic> canje) {
    final nombreEstudiante = '${canje['usuarios']['nombre']} ${canje['usuarios']['apellido']}';
    final List productos = canje['canje_prod'] ?? [];

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('TICKET VÁLIDO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Entregar a: $nombreEstudiante', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            const Text('Productos a entregar:', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            
            ...productos.map((prod) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.fastfood_outlined, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('${prod['cantidad']}x ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Expanded(child: Text('${prod['productos']['nombre']}', style: const TextStyle(fontSize: 16))),
                ],
              ),
            )),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _reanudarEscaner();
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx); 
                      await _confirmarEntrega(canje['id_canje']); 
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Confirmar Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ── ACTUALIZAR BASE DE DATOS ──
  Future<void> _confirmarEntrega(String idCanje) async {
    try {
      await _supabase.from('canjes').update({
        'estado': 'confirmado',
        'fecha_confirmacion': DateTime.now().toIso8601String()
      }).eq('id_canje', idCanje);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entrega registrada exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context); // Cierra el escáner
      }
    } catch (e) {
      _mostrarAlertaError('Error al guardar la confirmación.');
    }
  }

  // ── MANEJO DE ERRORES FLUIDO ──
  void _mostrarAlertaError(String mensaje) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white), 
            const SizedBox(width: 8), 
            Expanded(child: Text(mensaje))
          ]
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _reanudarEscaner();
    });
  }

  void _reanudarEscaner() {
    if (mounted) {
      setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Escanear Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // LA CÁMARA
          MobileScanner(
            controller: _scannerController,
            onDetect: _alDetectarCodigo,
          ),
          
          //  EL MARCO SEGURO 
          Positioned.fill(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  border: Border.all(color: PaletaColores.primary, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      spreadRadius: 10000, 
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          //  EL BOTÓN MANUAL ABAJO
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Apunta al código QR con la cámara', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _mostrarDialogoManual,
                  icon: const Icon(Icons.keyboard_alt_outlined),
                  label: const Text('Ingresar Código ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaletaColores.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),

          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            )
        ],
      ),
    );
  }
}