import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/presentation/routes/routes.dart';

class Canchas extends StatefulWidget {
  const Canchas({super.key});

  @override
  State<Canchas> createState() => _CanchasState();
}

class _CanchasState extends State<Canchas> {
  final List<Map<String, dynamic>> _locales = [
    {
      'nombre': 'Cancha N1',
      'direccion': 'Av. Principal 123, Ciudad',
      'descripcion':
          'Un espacio deportivo completo con equipo moderno y excelentes instalaciones.',
      'calificacion': 4.5,
      'imagen':
          'https://ichef.bbci.co.uk/ace/ws/640/cpsprodpb/238D/production/_95410190_gettyimages-488144002.jpg.webp',
      'servicios': {
        'Cancha de Futbol': true,
        'Cancha de Ecuavoley': true,
        'Equipos Deportivos': true,
        'Piscina': false,
      },
    },
    {
      'nombre': 'Cancha N2',
      'direccion': 'Calle Secundaria 456, Ciudad',
      'descripcion':
          'Espacio para entrenar con áreas de cardio y pesas libres.',
      'calificacion': 3.8,
      'imagen':
          'https://ichef.bbci.co.uk/ace/ws/640/cpsprodpb/238D/production/_95410190_gettyimages-488144002.jpg.webp',
      'servicios': {
        'Cancha de Futbol': true,
        'Cancha de Ecuavoley': false,
        'Equipos Deportivos': true,
        'Piscina': false,
      },
    },
  ];

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24.0),
              Text(
                "Encuentra las mejores canchas de la ciudad de Loja:",
                style: GoogleFonts.sansita(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildSearchBar(),
              const SizedBox(height: 12.0),
              const Divider(),
              const SizedBox(height: 12.0),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _locales.length,
                itemBuilder: (context, index) {
                  final local = _locales[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: const Color(0xFF19382F),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            left: 20,
                            bottom: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.yellow[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                '${local['calificacion']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: Image.network(
                            local['imagen'],
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                local['nombre'],
                                style: GoogleFonts.sansita(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    local['direccion'],
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                local['descripcion'],
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 16),
                              ),
                              const SizedBox(height: 15),
                              Divider(color: Colors.grey[300]),
                              Text(
                                'Servicios Disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: local['servicios']
                                    .entries
                                    .map<Widget>((entry) => _buildServiceChip(
                                        entry.key, entry.value))
                                    .toList(),
                              ),
                              const SizedBox(height: 15),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .end, // Posiciona el contenido al final
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, Routes.newReservePage);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                    icon: const Icon(
                                      Icons.event_available, // Ícono de reserva
                                      color: Colors.black,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF19382F),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              style: GoogleFonts.sansita(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Busca tu cancha...",
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, bool available) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: available ? Colors.white : Colors.white,
        ),
      ),
      backgroundColor: available ? Colors.green : Colors.grey,
    );
  }
}
