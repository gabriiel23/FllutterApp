import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importamos provider para acceder al ThemeProvider.

import 'package:flutterapp/theme/theme_provider.dart'; // Importamos el archivo donde está el ThemeProvider.

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0; // Índice para la página actual.

  final List<String> _routes = [
    '/second', // Ruta de la segunda página.
    '/third',  // Ruta de la tercera página.
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navegamos a la página correspondiente.
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Accedemos al ThemeProvider para poder cambiar el tema.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CanchAPP"),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny // Icono de sol si estamos en el tema oscuro.
                  : Icons
                      .nightlight_round, // Icono de luna si estamos en el tema claro.
            ),
            onPressed: () {
              // Cambiamos el tema cuando se presiona el botón.
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CanchAPPP",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 29, 84, 26),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: const Color.fromARGB(255, 128, 130, 127),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Sistema de reserva de canchas",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: const Color.fromARGB(255, 232, 224, 202),
                      ),
                    ],
                  ),
                )
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(40.0),
              child: Image.asset(
                'assets/fubol.gif',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            // Este es el switch para cambiar el tema manualmente
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tema oscuro",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 29, 84, 26),
                  ),
                ),
                Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider
                        .toggleTheme(); // Cambia el tema cuando se toca el switch.
                  },
                ),
                Text(
                  "Tema claro",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 29, 84, 26),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 29, 84, 26),
        unselectedItemColor: const Color.fromARGB(255, 128, 130, 127),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer), // Ícono relacionado con deportes
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), // Ícono para un calendario
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}
