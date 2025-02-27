import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importar SharedPreferences

class Canchas extends StatefulWidget {
  const Canchas({super.key});

  @override
  State<Canchas> createState() => _CanchasState();
}

class _CanchasState extends State<Canchas> {
  List<Map<String, dynamic>> _locales = [];
  bool _isLoading = true;
  String _userRole = ""; // Variable para almacenar el rol del usuario
  final String apiUrl = "http://localhost:3000/api/canchas";
  String baseUrl = "http://localhost:3000/";

  @override
  void initState() {
    super.initState();
    _fetchCanchas();
    _loadUserRole(); // Cargar el rol del usuario
  }

  /// Obtener el rol del usuario desde SharedPreferences
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRol') ?? ""; // Obtener el rol guardado
    });
  }

  /// Obtener la lista de canchas desde la API
  Future<void> _fetchCanchas() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _locales = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception("Error al obtener canchas");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF19382F),
        title: Text(
          "Espacios Deportivos",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _locales.isEmpty
                ? const Center(child: Text("No hay canchas disponibles"))
                : _buildCanchasList(),
      ),
      
      // Mostrar el botón solo si el usuario es "dueño"
      floatingActionButton: _userRole == "dueño"
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.newEspacioPage);
              },
              backgroundColor: const Color(0xFF19382F),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Si no es dueño, el botón no se muestra
    );
  }

  /// Construcción de la lista de canchas
  Widget _buildCanchasList() {
    return ListView.builder(
      itemCount: _locales.length,
      itemBuilder: (context, index) {
        final local = _locales[index];
        final double rating = (local['calificacion'] ?? 0).toDouble();
        final List<String> servicios = local['servicios'] ?? [];

        String imageUrl = "${baseUrl}uploads/${local['imagenes'][0].split('\\').last}";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          color: const Color(0xFF19382F),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local['nombre'] ?? 'Nombre no disponible',
                      style: GoogleFonts.sansita(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8.0),
                        Text(local['direccion'] ?? 'Dirección no disponible',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      local['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 25,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Servicios Disponibles",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 10,
                          children: servicios.map((servicio) {
                            return Chip(
                              label: Text(servicio, style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.newReservePage);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.event_available, color: Colors.black),
                          label: const Text(
                            'Reservar este espacio',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
