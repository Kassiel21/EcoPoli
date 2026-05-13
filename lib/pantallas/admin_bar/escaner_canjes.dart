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
  MobileScannerController _scannerController = MobileScannerController();

  // ── 1. LECTURA DEL CÓDIGO ──
  Future<void> _alDetectarCodigo(BarcodeCapture captura) async {
    if (_procesando) return; // Evita escanear 100 veces el mismo código en 1 segundo
    
    final List<Barcode> codigos = captura.barcodes;
    if (codigos.isEmpty || codigos.first.rawValue == null) return;

    final String codigoEscaneado = codigos.first.rawValue!;
    
    setState(() => _procesando = true);
    _scannerController.pause(); // Pausamos la cámara mientras validamos

    await _validarCanjeEnBaseDatos(codigoEscaneado);
  }

  // ── 2. VALIDACIÓN EN SUPABASE ──
  Future<void> _validarCanjeEnBaseDatos(String codigo) async {
    try {
      // Buscamos el canje y traemos los datos del usuario y los productos
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

      if (estado == 'confirmado') {
        _mostrarAlertaError('Este ticket ya fue entregado anteriormente.');
        return;
      }
      
      if (estado == 'expirado' || estado == 'cancelado') {
        _mostrarAlertaError('Este ticket está $estado y ya no es válido.');
        return;
      }

      // Si todo está bien, mostramos el resumen del pedido para entregar
      _mostrarResumenPedido(canje);

    } catch (e) {
      debugPrint('Error leyendo QR: $e');
      _mostrarAlertaError('Error de conexión al validar el código.');
    }
  }

  // ── 3. MOSTRAR PEDIDO Y CONFIRMAR ──
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
            
            // Lista de productos
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
                      Navigator.pop(ctx); // Cierra el modal
                      await _confirmarEntrega(canje['id_canje']); // Confirma en BD
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

  // ── 4. ACTUALIZAR BASE DE DATOS ──
  Future<void> _confirmarEntrega(String idCanje) async {
    try {
      await _supabase.from('canjes').update({
        'estado': 'confirmado',
        'fecha_confirmacion': DateTime.now().toIso8601String()
      }).eq('id_canje', idCanje);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entrega registrada exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context); // Cierra el escáner y vuelve al inicio del barman
      }
    } catch (e) {
      _mostrarAlertaError('Error al guardar la confirmación.');
    }
  }

  void _mostrarAlertaError(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('Alerta')]),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reanudarEscaner();
            },
            child: const Text('Entendido'),
          )
        ],
      ),
    );
  }

  void _reanudarEscaner() {
    setState(() => _procesando = false);
    _scannerController.start();
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
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _alDetectarCodigo,
          ),
          
          // Capa visual (Overlay oscuro con cuadro transparente en el medio)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: PaletaColores.primary,
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),
          
          // Texto de ayuda
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Text('Apunta la cámara al código QR del estudiante', style: TextStyle(color: Colors.white)),
              ),
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

// ── CLASE AUXILIAR PARA DIBUJAR EL RECUADRO DEL ESCÁNER ──
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2 ? cutOutSize / 2 : borderLength;
    final mBorderRadius = borderRadius > cutOutSize / 2 ? cutOutSize / 2 : borderRadius;

    final backgroundPaint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth;
    final boxPaint = Paint()..color = borderColor..style = PaintingStyle.fill..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - cutOutSize / 2 + borderOffset,
      cutOutSize - borderOffset * 2,
      cutOutSize - borderOffset * 2,
    );

    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(mBorderRadius)), boxPaint);
    
    // Esquinas del marco
    canvas.drawPath(Path()..moveTo(cutOutRect.left, cutOutRect.top + mBorderLength)..lineTo(cutOutRect.left, cutOutRect.top + mBorderRadius)..arcToPoint(Offset(cutOutRect.left + mBorderRadius, cutOutRect.top), radius: Radius.circular(mBorderRadius))..lineTo(cutOutRect.left + mBorderLength, cutOutRect.top), borderPaint);
    canvas.drawPath(Path()..moveTo(cutOutRect.right, cutOutRect.top + mBorderLength)..lineTo(cutOutRect.right, cutOutRect.top + mBorderRadius)..arcToPoint(Offset(cutOutRect.right - mBorderRadius, cutOutRect.top), radius: Radius.circular(mBorderRadius))..lineTo(cutOutRect.right - mBorderLength, cutOutRect.top), borderPaint);
    canvas.drawPath(Path()..moveTo(cutOutRect.left, cutOutRect.bottom - mBorderLength)..lineTo(cutOutRect.left, cutOutRect.bottom - mBorderRadius)..arcToPoint(Offset(cutOutRect.left + mBorderRadius, cutOutRect.bottom), radius: Radius.circular(mBorderRadius), clockwise: false)..lineTo(cutOutRect.left + mBorderLength, cutOutRect.bottom), borderPaint);
    canvas.drawPath(Path()..moveTo(cutOutRect.right, cutOutRect.bottom - mBorderLength)..lineTo(cutOutRect.right, cutOutRect.bottom - mBorderRadius)..arcToPoint(Offset(cutOutRect.right - mBorderRadius, cutOutRect.bottom), radius: Radius.circular(mBorderRadius), clockwise: false)..lineTo(cutOutRect.right - mBorderLength, cutOutRect.bottom), borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(borderColor: borderColor, borderWidth: borderWidth, overlayColor: overlayColor);
}