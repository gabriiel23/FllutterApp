import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Reserves extends StatefulWidget {
  const Reserves({super.key});

  @override
  _ReservesState createState() => _ReservesState();
}

class _ReservesState extends State<Reserves> {
  String? servicioId;
  String? espacioId;
  late Future<List<Reserva>> futureReservas;

  @override
  void initState() {
    super.initState();
    _cargarServicioId();
  }

  Future<void> _cargarServicioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      servicioId = prefs.getString('servicio_id');
      espacioId = prefs.getString('espacio_id');
    });

    if (servicioId != null) {
      setState(() {
        futureReservas = obtenerReservas(servicioId!);
      });
    }
  }

  Future<List<Reserva>> obtenerReservas(String servicioId) async {
    final String url =
        'https://back-canchapp.onrender.com/api/reservas/espacio/$espacioId';
    print("Obteniendo reservas desde: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Reserva.fromJson(json)).toList();
      } else {
        throw Exception("Error al obtener reservas: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  Future<void> cambiarEstadoReserva(
      String reservaId, String nuevoEstado) async {
    final String url =
        'https://back-canchapp.onrender.com/api/reservas/$reservaId/estado';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": nuevoEstado}),
      );

      if (response.statusCode == 200) {
        setState(() {
          futureReservas = obtenerReservas(servicioId!);
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
          "Tus Reservas",
          style: GoogleFonts.sansita(
            fontSize: 26,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: servicioId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19382F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      futureReservas = obtenerReservas(servicioId!);
                    });
                  },
                  child: Text(
                    "Actualizar Reservas",
                    style: GoogleFonts.sansita(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Reserva>>(
                    future: futureReservas,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error al cargar las reservas",
                            style: GoogleFonts.sansita(
                                fontSize: 18, color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "No hay reservas disponibles",
                            style: GoogleFonts.sansita(
                                fontSize: 18, color: Colors.grey[700]),
                          ),
                        );
                      }

                      List<Reserva> reservas = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reservas.length,
                        itemBuilder: (context, index) {
                          final reserva = reservas[index];

                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF19382F), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Fecha: ${reserva.fecha} - Hora: ${reserva.hora}",
                                  style: GoogleFonts.sansita(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF19382F),
                                  ),
                                ),
                                Text(
                                  "Servicio: ${reserva.servicio}",
                                  style: GoogleFonts.sansita(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Estado: ${reserva.estado}",
                                  style: GoogleFonts.sansita(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: reserva.estado == "Confirmada"
                                        ? Colors.green
                                        : reserva.estado == "Cancelada"
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        cambiarEstadoReserva(
                                            reserva.id, "Confirmada");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: Text("Confirmar", style: GoogleFonts.sansita(color: Colors.white)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        cambiarEstadoReserva(
                                            reserva.id, "Cancelada");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text("Cancelar", style: GoogleFonts.sansita(color: Colors.white)),
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
                ),
              ],
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

  Reserva({
    required this.id,
    required this.servicio,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.usuario,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json["_id"],
      servicio: json["servicio"]["nombre"],
      fecha: json["fecha"],
      hora: json["hora"],
      estado: json["estado"],
      usuario: json["usuario"]["nombre"],
    );
  }
}
