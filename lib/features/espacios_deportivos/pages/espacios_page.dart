import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'detalle_espacio_deportivo.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:flutterapp/config.dart';

class ListaEspaciosDeportivosPage extends StatefulWidget {
  @override
  _ListaEspaciosDeportivosPageState createState() =>
      _ListaEspaciosDeportivosPageState();
}

class _ListaEspaciosDeportivosPageState
    extends State<ListaEspaciosDeportivosPage> {
  List<dynamic> espacios = [];
  List<dynamic> espaciosFiltrados = [];
  bool isLoading = true;
  bool hasError = false;
  String baseUrl = Config.baseUrl;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    obtenerEspaciosDeportivos();
    mostrarDatosSharedPreferences();
  }

  Future<void> obtenerEspaciosDeportivos() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/espacio/espacios-deportivos'));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (mounted) {
          setState(() {
            if (decodedData is List) {
              espacios = decodedData;
            } else if (decodedData is Map && decodedData.containsKey('data')) {
              espacios = decodedData['data'];
            } else {
              hasError = true;
            }
            espaciosFiltrados = List.from(espacios);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  void filtrarEspacios(String query) {
    setState(() {
      espaciosFiltrados = espacios
          .where((espacio) => espacio['nombre']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
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
        title: Text("Espacios deportivos",
            style: GoogleFonts.sansita(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF19382F),
      ),
      body: Column(
        children: [
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Encuentra todos los mejores espacios deportivos dentro de la ciudad de Loja.",
              textAlign: TextAlign.start,
              style: GoogleFonts.sansita(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              onChanged: filtrarEspacios,
              style: TextStyle(color: Colors.white), // Texto blanco al escribir
              decoration: InputDecoration(
                hintText: "Buscar espacios deportivos...",
                hintStyle: GoogleFonts.sansita(color: Colors.grey.shade300),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                      left: 20, right: 8), // Separación del icono
                  child: Icon(Icons.search, color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Color(0xFF19382F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Bordes redondeados
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: 15, horizontal: 20), // Mejor alineación
              ),
            ),
          ),
          SizedBox(height: 20),
          Divider(color: Color(0xFF19382F)),
          SizedBox(height: 10),
          Expanded(
            child: isLoading
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
                              onPressed: obtenerEspaciosDeportivos,
                              child: Text("Reintentar"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: espaciosFiltrados.length,
                        itemBuilder: (context, index) {
                          final espacio = espaciosFiltrados[index];
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
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(10)),
                                          child: Image.network(
                                            imageUrl,
                                            width: 200,
                                            height: 200,
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
                                            espacio['nombre'] ?? "Sin nombre",
                                            style: GoogleFonts.sansita(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Divider(),
                                          Text(
                                            espacio['ubicacion'] ??
                                                "Ubicación desconocida",
                                            style: GoogleFonts.sansita(
                                                fontSize: 16,
                                                color: Colors.grey[800]),
                                          ),
                                          Text(
                                            espacio['descripcion'] ??
                                                "Descripción desconocida",
                                            style: GoogleFonts.sansita(
                                                fontSize: 14,
                                                color: Colors.grey[800]),
                                          ),
                                          Divider(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .start, // Alineado a la izquierda
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "✅  2",
                                                    style: GoogleFonts.sansita(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Canchas de fútbol",
                                                    style: GoogleFonts.sansita(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(width:20), // Espacio entre los dos bloques
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "✅  2",
                                                    style: GoogleFonts.sansita(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "Canchas de Voley",
                                                    style: GoogleFonts.sansita(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ],
                                              ),
                                            ],
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
    );
  }
}
