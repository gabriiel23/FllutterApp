import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Reserves_user extends StatefulWidget {
  const Reserves_user({super.key});

  @override
  _ReservesState createState() => _ReservesState();
}

class _ReservesState extends State<Reserves_user> {
  String? usuarioId;
  late Future<List<Reserva>> futureReservas;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioId();
  }

  Future<void> _cargarUsuarioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      usuarioId = prefs.getString('userId');
    });

    if (usuarioId != null) {
      setState(() {
        futureReservas = obtenerReservas(usuarioId!);
      });
    }
  }

  Future<List<Reserva>> obtenerReservas(String usuarioId) async {
    final String url =
        'https://back-canchapp.onrender.com/api/reservas/$usuarioId';
    print("Obteniendo reservas desde: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("Código de respuesta: \${response.statusCode}");
      print("Respuesta: \${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Reserva.fromJson(json)).toList();
      } else {
        throw Exception("Error al obtener reservas: \${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión: $e");
      throw Exception("Error de conexión: $e");
    }
  }

  Future<void> cambiarEstadoReserva(String reservaId) async {
    final String url =
        'https://back-canchapp.onrender.com/api/reservas/$reservaId/estado';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": "Cancelada"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          futureReservas = obtenerReservas(usuarioId!);
        });
      } else {
        throw Exception("Error al actualizar el estado de la reserva");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF19382F),
        title: Text(
          "Tus reservas",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: usuarioId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Reserva>>(
              future: futureReservas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("No hay reservas todavía"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay reservas todavía"));
                }

                List<Reserva> reservas = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final reserva = reservas[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19382F),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF19382F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ESPACIO: ${reserva.espacioDeportivo}", // Mostrar el nombre del espacio
                            style: GoogleFonts.sansita(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          Text(
                            "FECHA: ${reserva.fecha} - Hora: ${reserva.hora}",
                            style: GoogleFonts.sansita(
                              color: Colors.grey.shade300,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "SERVICIO: ${reserva.servicio}",
                            style: GoogleFonts.sansita(
                              color: Colors.grey.shade300,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "ESTADO: ${reserva.estado}",
                            style: GoogleFonts.sansita(
                              color: reserva.estado == "Confirmada"
                                  ? Colors.green
                                  : reserva.estado == "Cancelada"
                                      ? Colors.red
                                      : Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .end, // Alinea el botón a la derecha
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  cambiarEstadoReserva(reserva.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(
                                  "Cancelar",
                                  style: GoogleFonts.sansita(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class Reserva {
  final String id;
  final String servicio;
  final String fecha;
  final String hora;
  final String estado;
  final String usuario;
  final String espacioDeportivo; // Cambiado para reflejar el JSON

  Reserva({
    required this.id,
    required this.servicio,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.usuario,
    required this.espacioDeportivo, // Cambiado para reflejar el JSON
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json["_id"],
      servicio: json["servicio"]["nombre"],
      fecha: json["fecha"],
      hora: json["hora"],
      estado: json["estado"],
      usuario: json["usuario"]["nombre"],
      espacioDeportivo: json["espacio"]
          ["nombre"], // Ajustado para reflejar el JSON
    );
  }
}
