import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeAdminPage extends StatefulWidget {
  @override
  _HomeAdminPageState createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  DateTime _selectedDay = normalizeDate(DateTime.now());
  DateTime _focusedDay = normalizeDate(DateTime.now());
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  String? espacioId;
  String? nombreUsuario;
  List<Reserva> todasLasReservas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _cargarEspacioId();
    _cargarNombreUsuario(); // Cargar el nombre del usuario
  }

  Future<void> _cargarNombreUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); // Obtener el userId
    String? token = prefs.getString('userToken'); // Obtener el token

    if (userId != null && token != null) {
      try {
        String nombre = await obtenerNombreUsuario(
            userId, token); // Obtener el nombre del usuario
        setState(() {
          nombreUsuario =
              nombre; // Actualizar el estado con el nombre del usuario
        });
        await prefs.setString(
            'nombre_usuario', nombre); // Guardar el nombre en SharedPreferences
      } catch (e) {
        print("Error al cargar el nombre del usuario: $e");
        setState(() {
          nombreUsuario = 'Usuario'; // Valor predeterminado en caso de error
        });
      }
    } else {
      setState(() {
        nombreUsuario =
            'Usuario'; // Valor predeterminado si no hay userId o token
      });
    }
  }

  Future<String> obtenerNombreUsuario(String userId, String token) async {
    final String url =
        'https://back-canchapp.onrender.com/api/usuario/$userId'; // Endpoint para obtener el usuario por ID
    print("Obteniendo nombre del usuario desde: $url"); // Depuración

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token'
        }, // Enviar el token en el header
      );

      print("Código de respuesta: ${response.statusCode}"); // Depuración
      print("Respuesta: ${response.body}"); // Depuración

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData[
            'nombre']; // Ajusta según la estructura de la respuesta
      } else {
        throw Exception(
            "Error al obtener el nombre del usuario: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión: $e"); // Depuración
      throw Exception("Error de conexión: $e");
    }
  }

  Future<void> _cargarEspacioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      espacioId = prefs.getString('espacio_id');
    });

    if (espacioId != null) {
      await obtenerTodasLasReservas();
    }
  }

  Future<void> obtenerTodasLasReservas() async {
    final String url =
        'https://back-canchapp.onrender.com/api/reservas/espacio/$espacioId';
    print("Obteniendo todas las reservas desde: $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("Código de respuesta: ${response.statusCode}");
      print("Respuesta: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          todasLasReservas =
              data.map((json) => Reserva.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Error al obtener reservas: ${response.statusCode}");
      }
    } catch (e) {
      print("Error de conexión: $e");
      setState(() {
        isLoading = false;
      });
      throw Exception("Error de conexión: $e");
    }
  }

  List<Reserva> filtrarReservasPorFecha(DateTime fecha) {
    return todasLasReservas.where((reserva) {
      return isSameDay(normalizeDate(DateTime.parse(reserva.fecha)), fecha);
    }).toList();
  }

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    DateTime normalizedSelectedDay = normalizeDate(_selectedDay);
    List<Reserva> reservasDelDia =
        filtrarReservasPorFecha(normalizedSelectedDay);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF19382F),
                Color.fromARGB(255, 38, 94, 78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            leading: PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'Login':
                    Navigator.pushNamed(context, Routes.login);
                    break;
                  case 'Registro':
                    Navigator.pushNamed(context, Routes.registration);
                    break;
                  case 'Configuración':
                    Navigator.pushNamed(context, Routes.settings);
                    break;
                  case 'Cerrar sesión':
                    Navigator.pushReplacementNamed(context, Routes.logout);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return ['Login', 'Registro', 'Configuración', 'Cerrar sesión']
                    .map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(
                      choice,
                      style: GoogleFonts.sansita(),
                    ),
                  );
                }).toList();
              },
              icon: Container(
                decoration: BoxDecoration(),
                padding: EdgeInsets.all(8),
                child: const Icon(
                  Icons.menu_open_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF19382F),
                      const Color.fromARGB(255, 38, 94, 78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "⚽  CanchAPP",
                                      style: GoogleFonts.sansita(
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Hola ${nombreUsuario ?? 'Usuario'}",
                                      style: GoogleFonts.sansita(
                                        fontSize: constraints.maxWidth < 350
                                            ? 30
                                            : 38, // Ajusta el tamaño dinámicamente
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          const Shadow(
                                            offset: Offset(5.0, 5.0),
                                            blurRadius: 8.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Aquí podrás ver todas las novedades sobre tu espacio deportivo",
                                      style: GoogleFonts.sansita(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: constraints.maxWidth > 300
                                    ? Image.network(
                                        'https://cdn-icons-png.flaticon.com/512/78/78948.png',
                                        height: constraints.maxWidth < 350
                                            ? 100
                                            : 150, // Ajusta la altura de la imagen
                                        fit: BoxFit.contain,
                                      )
                                    : Container(), // Oculta la imagen en pantallas extremadamente pequeñas
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_month, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    "Calendario",
                    style: GoogleFonts.sansita(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = normalizeDate(selectedDay);
                    _focusedDay = normalizeDate(focusedDay);
                  });
                },
                locale: 'es_ES',
                headerStyle: HeaderStyle(
                  titleTextStyle:
                      GoogleFonts.sansita(fontSize: 20.0, color: Colors.black),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.arrow_back, color: Colors.green),
                  rightChevronIcon:
                      Icon(Icons.arrow_forward, color: Colors.green),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.sansita(),
                  weekendTextStyle: GoogleFonts.sansita(),
                  selectedTextStyle: GoogleFonts.sansita(color: Colors.white),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: GoogleFonts.sansita(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  outsideTextStyle: GoogleFonts.sansita(color: Colors.grey),
                  disabledTextStyle:
                      GoogleFonts.sansita(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Reservas para el ${normalizedSelectedDay.toLocal().toString().split(' ')[0]}",
                style: GoogleFonts.sansita(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (reservasDelDia.isEmpty)
                Center(
                  child: Text(
                    "No hay reservas en esta fecha",
                    style: GoogleFonts.sansita(fontSize: 16),
                  ),
                )
              else
                Column(
                  children: reservasDelDia
                      .map((reserva) => ListTile(
                            leading:
                                Icon(Icons.sports_soccer, color: Colors.green),
                            title: Text(reserva.servicio,
                                style: GoogleFonts.sansita()),
                            subtitle: Text("Hora: ${reserva.hora}",
                                style: GoogleFonts.sansita()),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.message_outlined, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    "Opiniones Usuarios:",
                    style: GoogleFonts.sansita(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.person, color: Colors.green),
                ),
                title: Text("Juan Pérez", style: GoogleFonts.sansita()),
                subtitle: Text(
                  "Excelente servicio, rápido y confiable.",
                  style: GoogleFonts.sansita(),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text("Ana Gómez", style: GoogleFonts.sansita()),
                subtitle: Text(
                  "Reservar canchas nunca fue tan fácil.",
                  style: GoogleFonts.sansita(),
                ),
              ),
            ],
          ),
        ),
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
