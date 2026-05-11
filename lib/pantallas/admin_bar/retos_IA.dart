import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eco_poli/config/paleta_colores.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PantallaGenerarRetosIA extends StatefulWidget {
  const PantallaGenerarRetosIA({super.key});

  @override
  State<PantallaGenerarRetosIA> createState() => _PantallaGenerarRetosIAState();
}

class _PantallaGenerarRetosIAState extends State<PantallaGenerarRetosIA> {
  //  API KEY DE GOOGLE GEMINI
  final String _apiKey = 'AIzaSyCeHFahJim6Vi_nRSD1TE9iuRhrOl3ySbw'; 
  
  bool _estaCargando = false;
  List<Map<String, dynamic>> _retosGenerados = [];

  //  CONEXIÓN CON GEMINI ──────────────────────
  Future<void> _generarRetosConIA() async {
    if (_apiKey.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Falta colocar la API Key de Gemini')));
      return;
    }

    setState(() => _estaCargando = true);

    try {
      // Inicializamos el modelo de IA 
      final modelo = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);

      // Prompt 
      const prompt = '''
      Eres un experto en gamificación y ecología para estudiantes universitarios.
      Genera 5 retos semanales para la aplicación "EcoPoli" de la ESPOCH.
      El objetivo es incentivar a los estudiantes a reciclar botellas de plástico PET en los bares de la facultad.
      
      Reglas estrictas:
      - puntos_recompensa: Entre 50 y 300.
      - meta_botellas: Entre 50 y 300.
      - dificultad: Solo puede ser "facil", "medio" o "dificil".
      
      Devuelve ÚNICAMENTE un arreglo JSON válido con esta estructura exacta, sin texto adicional ni formato markdown (sin ```json):
      [
        {
          "titulo": "Nombre del reto atractivo",
          "descripcion": "Descripción motivadora del reto",
          "puntos_recompensa": 100,
          "meta_botellas": 5,
          "dificil": "medio",
          "instrucciones": "Paso 1: junta las botellas. Paso 2: entrégalas en el bar."
        }
      ]
      ''';

      //  Enviamos la petición
      final respuesta = await modelo.generateContent([Content.text(prompt)]);
      final textoRespuesta = respuesta.text ?? '[]';

      //  Limpiamos la respuesta
      String jsonLimpio = textoRespuesta.trim();
      if (jsonLimpio.startsWith('```json')) {
        jsonLimpio = jsonLimpio.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      //  Convertimos el JSON de texto a una Lista de Dart
      final List<dynamic> datosDecodificados = jsonDecode(jsonLimpio);
      
      setState(() {
        _retosGenerados = List<Map<String, dynamic>>.from(datosDecodificados);
      });

    } catch (e) {
      debugPrint('❌ EL ERROR REAL ES: $e'); // Esto lo imprimirá en tu consola de VS Code
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 6), // Lo dejamos más tiempo para poder leerlo
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaColores.background,
      appBar: AppBar(
        title: const Text('IA: Creador de Retos 🤖', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaColores.primary, // Color distintivo para la IA
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── CABECERA EXPLICATIVA ──
          Container(
            padding: const EdgeInsets.all(20),
            color: PaletaColores.fieldBackground,
            child: const Text(
              'Usa la Inteligencia Artificial para generar dinámicas atractivas que motiven a los estudiantes de la ESPOCH a reciclar más esta semana.',
              style: TextStyle(color:PaletaColores.primary, fontWeight: FontWeight.w500),
            ),
          ),

          // ── BOTÓN DE GENERACIÓN ──
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _estaCargando ? null : _generarRetosConIA,
                icon: _estaCargando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _estaCargando ? 'Pensando...' : 'Generar 5 Retos Mágicos', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaColores.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),

          // ── LISTA DE RETOS GENERADOS ──
          Expanded(
            child: _retosGenerados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Esperando instrucciones...', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _retosGenerados.length,
                    itemBuilder: (context, index) {
                      final reto = _retosGenerados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reto['titulo'] ?? 'Sin título', 
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: PaletaColores.textPrimary)
                                    )
                                  ),
                                  Chip(
                                    label: Text(
                                      '${reto['dificil']}'.toUpperCase(), 
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                    backgroundColor: Colors.purple.shade50,
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(reto['descripcion'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.recycling, size: 18, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text('Meta: ${reto['meta_botellas']} PET', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text('+${reto['puntos_recompensa']} puntos', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.amber, fontSize: 16)),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── BOTÓN DE GUARDAR EN BASE DE DATOS (Solo si hay retos) ──
          if (_retosGenerados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paso 3: Falta conectarlo a Supabase')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Aprobar y Publicar a Estudiantes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}