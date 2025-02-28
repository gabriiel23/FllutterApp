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
  final String url = 'https://back-canchapp.onrender.com/api/reservas/espacio/$espacioId';
  print("Obteniendo reservas desde: $url"); // <-- Depuración

  try {
    final response = await http.get(Uri.parse(url));

    print("Código de respuesta: ${response.statusCode}"); // <-- Depuración
    print("Respuesta: ${response.body}"); // <-- Depuración

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Reserva.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener reservas: ${response.statusCode}");
    }
  } catch (e) {
    print("Error de conexión: $e"); // <-- Depuración
    throw Exception("Error de conexión: $e");
  }
}

  Future<void> cambiarEstadoReserva(String reservaId, String nuevoEstado) async {
    final String url = 'https://back-canchapp.onrender.com/api/reservas/$reservaId/estado';
    
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
        "Tus reservas",
        style: GoogleFonts.sansita(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    body: servicioId == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Botón de actualizar reservas
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    // Reiniciar el estado de carga
                    futureReservas = obtenerReservas(servicioId!);
                  });
                },
                child: Text(
                  "Actualizar reservas",
                  style: GoogleFonts.sansita(fontSize: 16),
                ),
              ),
              // Lista de reservas
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
                          style: GoogleFonts.sansita(fontSize: 16),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No hay reservas disponibles",
                          style: GoogleFonts.sansita(fontSize: 16),
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
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F7E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF19382F)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Fecha: ${reserva.fecha} - Hora: ${reserva.hora}",
                                style: GoogleFonts.sansita(
                                  color: const Color(0xFF19382F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Servicio: ${reserva.servicio}",
                                style: GoogleFonts.sansita(
                                  color: const Color(0xFF19382F),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Estado: ${reserva.estado}",
                                style: GoogleFonts.sansita(
                                  color: reserva.estado == "Confirmada"
                                      ? Colors.green
                                      : reserva.estado == "Cancelada"
                                          ? Colors.red
                                          : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      cambiarEstadoReserva(reserva.id, "Confirmada");
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text("Confirmar"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      cambiarEstadoReserva(reserva.id, "Cancelada");
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text("Cancelar"),
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
      servicio: json["servicio"]["nombre"], // Asegúrate de que el JSON contiene el nombre del servicio
      fecha: json["fecha"],
      hora: json["hora"],
      estado: json["estado"],
      usuario: json["usuario"]["nombre"],
    );
  }
}
