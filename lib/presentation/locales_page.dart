import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/fragments/custom_navigation.dart';
import 'package:flutterapp/presentation/routes/routes.dart';

class LocalesPage extends StatelessWidget {
  final List<Map<String, dynamic>> locales = [
    {
      'nombre': 'Gimnasio FitMax',
      'direccion': 'Av. Principal 123, Ciudad',
      'descripcion': 'Un gimnasio completo con equipo moderno y excelentes instalaciones.',
      'imagen': 'https://via.placeholder.com/300',
      'servicios': {
        'rentaEquipoDeportivo': true,
        'entrenadoresPersonales': true,
        'piscina': true,
        'sauna': false,
        'turco': false,
        'duchas': true,
        'vestidores': true,
      },
    },
    {
      'nombre': 'Centro Deportivo Elite',
      'direccion': 'Calle Secundaria 456, Ciudad',
      'descripcion': 'Espacio para entrenar con áreas de cardio y pesas libres.',
      'imagen': 'https://via.placeholder.com/300',
      'servicios': {
        'rentaEquipoDeportivo': false,
        'entrenadoresPersonales': true,
        'piscina': false,
        'sauna': true,
        'turco': true,
        'duchas': true,
        'vestidores': true,
      },
    },
    {
      'nombre': 'Spa y Fitness Center',
      'direccion': 'Boulevard 789, Ciudad',
      'descripcion': 'Relájate y mantente en forma con nuestras opciones de spa y fitness.',
      'imagen': 'https://via.placeholder.com/300',
      'servicios': {
        'rentaEquipoDeportivo': true,
        'entrenadoresPersonales': false,
        'piscina': true,
        'sauna': true,
        'turco': true,
        'duchas': true,
        'vestidores': false,
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Locales',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: locales.length,
        itemBuilder: (context, index) {
          final local = locales[index];
          return Card(
            margin: EdgeInsets.all(15),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        local['direccion'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        local['descripcion'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 15),
                      Divider(color: Colors.grey[300]),
                      Text(
                        'Servicios Disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[600],
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildServiceChip('Renta de Equipo Deportivo',
                              local['servicios']['rentaEquipoDeportivo']),
                          _buildServiceChip('Entrenadores Personales',
                              local['servicios']['entrenadoresPersonales']),
                          _buildServiceChip(
                              'Piscina', local['servicios']['piscina']),
                          _buildServiceChip('Sauna', local['servicios']['sauna']),
                          _buildServiceChip('Turco', local['servicios']['turco']),
                          _buildServiceChip('Duchas', local['servicios']['duchas']),
                          _buildServiceChip(
                              'Vestidores', local['servicios']['vestidores']),
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
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1, // Índice de la página actual
        onTap: (index) {
          // Navegar según el índice
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, Routes.home);
              break;
            case 1:
              break; // Ya estamos en Locales
            case 2:
              Navigator.pushReplacementNamed(context, Routes.reserve);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, Routes.events);
              break;
          }
        },
      ),
    );
  }

  Widget _buildServiceChip(String label, bool available) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: available ? Colors.white : Colors.grey[400],
        ),
      ),
      backgroundColor: available ? Colors.teal : Colors.grey[300],
    );
  }
}
