import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'crear_servicio_page.dart';
import 'package:flutterapp/config.dart';

class DetalleEspacioDeportivoPage extends StatefulWidget {
  final Map<String, dynamic> espacio;

  DetalleEspacioDeportivoPage({required this.espacio});

  @override
  _DetalleEspacioDeportivoPageState createState() =>
      _DetalleEspacioDeportivoPageState();
}

class _DetalleEspacioDeportivoPageState
    extends State<DetalleEspacioDeportivoPage> {
  late String espacioId;
  List<dynamic> servicios = [];
  bool isLoading = true;
  String baseUrl = Config.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadEspacioId();
  }

  Future<void> _loadEspacioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    espacioId = prefs.getString('espacio_id') ?? '';
    _fetchServicios();
  }

  Future<void> _fetchServicios() async {
    final response = await http.get(Uri.parse('$baseUrl/api/$espacioId'));

    if (response.statusCode == 200) {
      setState(() {
        servicios = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load services');
    }
  }

  @override
  Widget build(BuildContext context) {
    String baseUrl = Config.baseUrl;
    String imageUrl = widget.espacio['imagen'] != null
        ? '$baseUrl${widget.espacio['imagen']}'
        : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.espacio['nombre'] ?? "Detalles",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageUrl.isNotEmpty
                  ? Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          height: 250,
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(height: 200, color: Colors.grey[300]),
              SizedBox(height: 30),
              _buildDetailRow("Ubicación:", widget.espacio['ubicacion']),
              Divider(),
              _buildDetailRow("Descripción:", widget.espacio['descripcion']),
              Divider(),
              _buildDetailRow(
                  "Propietario:", widget.espacio['propietario']?['nombre']),
              Divider(),
              _buildDetailRow("Email del Propietario:",
                  widget.espacio['propietario']?['email']),
              SizedBox(height: 10),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: servicios.length,
                      itemBuilder: (context, index) {
                        var servicio = servicios[index];
                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              servicio['nombre'] ?? 'Servicio no disponible',
                              style: GoogleFonts.sansita(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              servicio['descripcion'] ??
                                  'Descripción no disponible',
                              style: GoogleFonts.sansita(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                    'servicio_id', servicio['_id']);
                                print(
                                    "ID del servicio guardado: ${servicio['_id']}");

                                Navigator.pushNamed(context, '/newReserve');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0xFF19382F), // Color de fondo
                                foregroundColor:
                                    Colors.white, // Color del texto
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Bordes redondeados
                                ),
                              ),
                              child: Text(
                                "Reservar",
                                style: GoogleFonts.sansita(fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CrearServicioPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF19382F), // Color de fondo
                    foregroundColor: Colors.white, // Color del texto e icono
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Bordes redondeados
                    ),
                  ),
                  icon:
                      Icon(Icons.add, color: Colors.white), // Ícono de "Nuevo"
                  label: Text("Crear Servicio",
                      style: GoogleFonts.sansita(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(value ?? "No disponible",
            style: GoogleFonts.sansita(fontSize: 16)),
        SizedBox(height: 10),
      ],
    );
  }
}
