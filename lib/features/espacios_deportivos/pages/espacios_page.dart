import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Importamos SharedPreferences
import 'detalle_espacio_deportivo.dart'; // Importamos la pantalla de detalle
import 'package:flutterapp/core/routes/routes.dart'; // Asegúrate de importar el archivo donde defines Routes

class ListaEspaciosDeportivosPage extends StatefulWidget {
  @override
  _ListaEspaciosDeportivosPageState createState() =>
      _ListaEspaciosDeportivosPageState();
}

class _ListaEspaciosDeportivosPageState
    extends State<ListaEspaciosDeportivosPage> {
  List<dynamic> espacios = [];
  bool isLoading = true;
  bool hasError = false;
  String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    obtenerEspaciosDeportivos();
    mostrarDatosSharedPreferences(); // Llamar la función al iniciar la pantalla
  }

  Future<void> obtenerEspaciosDeportivos() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/espacios-deportivos'));

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

  Future<void> mostrarDatosSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("🔹 Datos en SharedPreferences:");
    prefs.getKeys().forEach((key) {
      print("$key: ${prefs.get(key)}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Espacios Deportivos",
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error al cargar los espacios deportivos",
                          style: GoogleFonts.lato(
                              fontSize: 16, color: Colors.red)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: obtenerEspaciosDeportivos,
                        child: Text("Reintentar"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: espacios.length,
                  itemBuilder: (context, index) {
                    final espacio = espacios[index];
                    String imageUrl = espacio['imagen'] != null
                        ? '$baseUrl${espacio['imagen']}'
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
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                                      espacio['nombre'] ??
                                          "Sin nombre",
                                      style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      espacio['ubicacion'] ??
                                          "Ubicación desconocida",
                                      style: GoogleFonts.lato(
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
    );
  }
}
