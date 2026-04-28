import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class Reserves extends StatefulWidget {
  const Reserves({super.key});

  @override
  _ReservesState createState() => _ReservesState();
}

class _ReservesState extends State<Reserves> {
  String? servicioId;
  String? espacioId;
  late Future<List<Reserva>> futureReservas;

  final Color _primaryDeep = const Color(0xFF19382F);
  final Color _bg = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    futureReservas = Future.value([]); // Inicializar
    _cargarServicioId();
  }

  Future<void> _cargarServicioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEspacioId = prefs.getString('espacio_id');

    if (storedEspacioId != null) {
      setState(() {
        servicioId = prefs.getString('servicio_id');
        espacioId = storedEspacioId;
        futureReservas = obtenerReservas(espacioId!);
      });
    } else {
      String? userId = prefs.getString('userId');
      if (userId != null) {
        try {
          final response = await http.get(Uri.parse('${Config.baseUrl}/api/espacio/espacios-deportivos/$userId'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data is List && data.isNotEmpty) {
              String fetchedId = data[0]['_id'];
              await prefs.setString('espacio_id', fetchedId);
              setState(() {
                espacioId = fetchedId;
                futureReservas = obtenerReservas(espacioId!);
              });
            } else {
              setState(() {
                espacioId = 'vacio';
                futureReservas = Future.value([]);
              });
            }
          } else {
            setState(() {
              espacioId = 'vacio';
              futureReservas = Future.value([]);
            });
          }
        } catch (e) {
          setState(() {
            espacioId = 'vacio';
            futureReservas = Future.error(e);
          });
        }
      } else {
        setState(() {
          espacioId = 'vacio';
          futureReservas = Future.value([]);
        });
      }
    }
  }

  Future<List<Reserva>> obtenerReservas(String eId) async {
    final String url = '${Config.baseUrl}/api/reservas/espacio/$eId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Reserva.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception("Error al obtener reservas: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  Future<void> cambiarEstadoReserva(String reservaId, String nuevoEstado) async {
    final String url = '${Config.baseUrl}/api/reservas/$reservaId/estado';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": nuevoEstado}),
      );

      if (response.statusCode == 200) {
        setState(() {
          futureReservas = obtenerReservas(espacioId!);
        });
      } else {
        throw Exception("Error al actualizar el estado");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryDeep,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reservas',
                        style: GoogleFonts.sansita(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (espacioId != null) {
                            setState(() {
                              futureReservas = obtenerReservas(espacioId!);
                            });
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona los juegos programados',
                    style: GoogleFonts.sansita(
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (espacioId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (espacioId == 'vacio') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stadium_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text("No tienes un espacio deportivo registrado", style: GoogleFonts.sansita(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return FutureBuilder<List<Reserva>>(
      future: futureReservas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error al cargar reservas", style: GoogleFonts.sansita(color: Colors.red)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text("No hay reservas aún", style: GoogleFonts.sansita(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        List<Reserva> reservas = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: reservas.length,
          itemBuilder: (context, index) {
            final reserva = reservas[index];
            Color statusColor = reserva.estado == "Confirmada" 
                ? Colors.green 
                : (reserva.estado == "Cancelada" ? Colors.red : Colors.orange);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          reserva.estado.toUpperCase(),
                          style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      Text(
                        reserva.fecha,
                        style: GoogleFonts.sansita(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reserva.servicio,
                    style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(reserva.hora, style: GoogleFonts.sansita(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => cambiarEstadoReserva(reserva.id, "Cancelada"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.redAccent,
                          ),
                          child: Text("Cancelar", style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => cambiarEstadoReserva(reserva.id, "Confirmada"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Confirmar", style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
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
      servicio: json["servicio"]?["nombre"] ?? "Servicio",
      fecha: json["fecha"] ?? "N/A",
      hora: json["hora"] ?? "N/A",
      estado: json["estado"] ?? "Pendiente",
      usuario: json["usuario"]?["nombre"] ?? "Usuario",
    );
  }
}
