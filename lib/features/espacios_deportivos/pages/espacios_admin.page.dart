import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detalle_espacio_deportivo.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:flutterapp/config.dart';

class ListaEspaciosAdminDeportivosPage extends StatefulWidget {
  @override
  _ListaEspaciosDeportivosPageState createState() =>
      _ListaEspaciosDeportivosPageState();
}

class _ListaEspaciosDeportivosPageState
    extends State<ListaEspaciosAdminDeportivosPage> {
  List<dynamic> espacios = [];
  bool isLoading = true;
  bool hasError = false;
  String baseUrl = Config.baseUrl;

  @override
  void initState() {
    super.initState();
    obtenerEspaciosDeportivos();
  }

  Future<void> obtenerEspaciosDeportivos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? propietarioId = prefs.getString('userId');

      if (propietarioId == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
          Uri.parse('$baseUrl/api/espacio/espacios-deportivos/$propietarioId'));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          if (decodedData is List) {
            espacios = decodedData;
          } else if (decodedData is Map && decodedData.containsKey('data')) {
            espacios = decodedData['data'];
          } else {
            hasError = true;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> guardarEspacioSeleccionado(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('espacio_id', id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF19382F),
        title: Text(
          "Tu espacio deportivo",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error al cargar los espacios deportivos",
                          style: GoogleFonts.sansita(
                              fontSize: 16, color: Colors.red)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true; // Activar el estado de carga
                            hasError = false; // Reiniciar el estado de error
                          });
                          await obtenerEspaciosDeportivos(); // Llamar a la función para obtener los espacios
                        },
                        child: Text(
                          "Reintentar",
                          style: GoogleFonts.sansita(fontSize: 16),
                        ),
                      )
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Text(
                        "⚽  Revisa las novedades sobre tu espacio deportivo:",
                        style: GoogleFonts.sansita(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Divider(),
                      SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          itemCount: espacios.length,
                          itemBuilder: (context, index) {
                            final espacio = espacios[index];
                            String imageUrl = espacio['imagen'] != null &&
                                    espacio['imagen'].startsWith('http')
                                ? espacio['imagen']
                                : '';

                            return GestureDetector(
                              onTap: () async {
                                await guardarEspacioSeleccionado(
                                    espacio['_id'] ?? '');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleEspacioDeportivoPage(
                                            espacio: espacio),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                    left: Radius.circular(10)),
                                            child: Image.network(
                                              imageUrl,
                                              width: 160,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[600]),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                          ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              espacio['nombre'] ?? "Sin nombre",
                                              style: GoogleFonts.sansita(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              espacio['ubicacion'] ??
                                                  "Ubicación desconocida",
                                              style: GoogleFonts.sansita(
                                                  fontSize: 17,
                                                  color: Colors.grey[900]),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              espacio['descripcion'] ??
                                                  "Descripción desconocida",
                                              style: GoogleFonts.sansita(
                                                  fontSize: 14,
                                                  color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: espacios.isEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.newEspacioPage);
              },
              backgroundColor: const Color(0xFF19382F),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
