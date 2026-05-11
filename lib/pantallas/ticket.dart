import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PantallaTicket extends StatelessWidget {
  final String codigoVerificacion;
  final List<Map<String, dynamic>> productos;
  final int totalPuntos;

  const PantallaTicket({
    super.key,
    required this.codigoVerificacion,
    required this.productos,
    required this.totalPuntos,
  });

  @override
  Widget build(BuildContext context) {
    // WillPopScope (o PopScope) evita que el usuario regrese al carrito usando el botón de atrás del celular
    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: PaletaColores.primary, // Fondo verde para que se vea como un éxito
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              //  ICONO DE ÉXITO
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 100),
              const SizedBox(height: 16),
              const Text(
                '¡Canje Exitoso!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Muestra este código en el bar',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),

              //  LA TARJETA DEL TICKET (El Recibo)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // El Código Gigante
                      Text(
                        codigoVerificacion,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: PaletaColores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Código QR
                      QrImageView(
                        data: codigoVerificacion, // El dato que se convierte en QR
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.Q, // Nivel de corrección alto
                      ),

                      // Lista de cosas que debe entregarle el del bar
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Resumen del pedido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: productos.length,
                          itemBuilder: (context, index) {
                            final item = productos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item['cantidad']}x ${item['nombre']}'),
                                  Text('${(item['puntos_costo'] ?? 0) * (item['cantidad'] ?? 1)} puntos', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Total descontado
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total descontado:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          Text(
                            '-$totalPuntos puntos',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PaletaColores.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 3. BOTÓN PARA VOLVER
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaletaColores.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            // Cierra el ticket y vuelve al Home limpio
                            Navigator.pop(context);
                          },
                          child: const Text('Volver al Inicio', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}