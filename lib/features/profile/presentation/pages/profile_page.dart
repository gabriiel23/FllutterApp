import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userId;
  String? token;
  String? userRol;

  // Variable para almacenar los datos del perfil de jugador
  Map<String, dynamic>? jugadorData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      token = prefs.getString('userToken');
      userRol = prefs.getString('userRol'); // Obtener el rol del usuario

      print("🔹 Recuperado de SharedPreferences:");
      print("   - userId: $userId");
      print("   - userToken: $token");
      print("   - userRol: $userRol");

      if (userId == null || token == null) {
        throw Exception("No se encontró userId o token en SharedPreferences.");
      }

      final response = await http.get(
        Uri.parse('https://back-canchapp.onrender.com/api/usuario/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });

        // Verificar si el perfil de jugador existe
        if (userRol == 'jugador') {
          final jugadorResponse = await http.get(
            Uri.parse('https://back-canchapp.onrender.com/api/jugadores/usuario/$userId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (jugadorResponse.statusCode == 200) {
            setState(() {
              jugadorData = json.decode(jugadorResponse.body);
            });
          } else {
            print(
                "🔴 Error al obtener el perfil de jugador: ${jugadorResponse.statusCode}");
          }
        }
      } else {
        throw Exception(
            'Error al obtener datos del usuario: ${response.statusCode}');
      }
    } catch (e) {
      print("🔴 Error: $e");
      setState(() {
        isLoading = false;
        userData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Perfil",
          style: GoogleFonts.sansita(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF19382F),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("Error al cargar datos"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(userData!['avatar'] ??
                            'https://w7.pngwing.com/pngs/1008/377/png-transparent-computer-icons-avatar-user-profile-avatar-heroes-black-hair-computer.png'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userData!['nombre'],
                        style: GoogleFonts.sansita(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userData!['email'],
                        style: GoogleFonts.sansita(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 30),
                      ListTile(
                        leading:
                            Icon(Icons.phone, color: const Color(0xFF19382F)),
                        title: Text('Teléfono', style: GoogleFonts.sansita()),
                        subtitle: Text(userData!['telefono'] ?? 'No disponible',
                            style: GoogleFonts.sansita()),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.calendar_today,
                            color: const Color(0xFF19382F)),
                        title:
                            Text('Miembro desde', style: GoogleFonts.sansita()),
                        subtitle: Text(
                            userData!['fechaRegistro'] ?? 'No disponible',
                            style: GoogleFonts.sansita()),
                      ),
                      const SizedBox(height: 20),

                      // Si el perfil de jugador existe, mostramos su información
                      if (jugadorData != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Perfil de Jugador",
                                style: GoogleFonts.sansita(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: Icon(Icons.sports_soccer,
                                  color: const Color(0xFF19382F)),
                              title: Text('Posición',
                                  style: GoogleFonts.sansita()),
                              subtitle: Text(
                                  jugadorData!['posicion'] ?? 'No disponible',
                                  style: GoogleFonts.sansita()),
                            ),
                            ListTile(
                              leading: Icon(Icons.accessibility,
                                  color: const Color(0xFF19382F)),
                              title: Text('Estatura',
                                  style: GoogleFonts.sansita()),
                              subtitle: Text(
                                  jugadorData!['estatura']?.toString() ??
                                      'No disponible',
                                  style: GoogleFonts.sansita()),
                            ),
                            ListTile(
                              leading: Icon(Icons.date_range,
                                  color: const Color(0xFF19382F)),
                              title: Text('Edad', style: GoogleFonts.sansita()),
                              subtitle: Text(
                                  jugadorData!['edad']?.toString() ??
                                      'No disponible',
                                  style: GoogleFonts.sansita()),
                            ),
                            // Mostrar atributos del jugador
                            Text('Atributos',
                                style: GoogleFonts.sansita(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ListTile(
                              leading: Icon(Icons.sports,
                                  color: const Color(0xFF19382F)),
                              title: Text('Tiro', style: GoogleFonts.sansita()),
                              subtitle: Text(
                                  jugadorData!['atributos']['Tiro']
                                          ?.toString() ??
                                      'No disponible',
                                  style: GoogleFonts.sansita()),
                            ),
                            ListTile(
                              leading: Icon(Icons.sports,
                                  color: const Color(0xFF19382F)),
                              title:
                                  Text('Regate', style: GoogleFonts.sansita()),
                              subtitle: Text(
                                  jugadorData!['atributos']['Regate']
                                          ?.toString() ??
                                      'No disponible',
                                  style: GoogleFonts.sansita()),
                            ),
                            // Añadir más atributos según sea necesario
                          ],
                        )
                      // Si el perfil de jugador no existe, mostramos el botón
                      else if (userRol == "jugador")
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/profilePlayer");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF19382F),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            "Crear perfil de jugador",
                            style: GoogleFonts.sansita(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
