import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Importamos provider para acceder al ThemeProvider.

import 'package:flutterapp/theme/theme_provider.dart'; // Importamos el archivo donde está el ThemeProvider.

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Accedemos al ThemeProvider para poder cambiar el tema.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi App en Flutter"),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny  // Icono de sol si estamos en el tema oscuro.
                  : Icons.nightlight_round,  // Icono de luna si estamos en el tema claro.
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
                  "Mi App en Flutter",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 232, 224, 202),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                Text(
                  "Hecha por mi mismo",
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
                'assets/casas.gif',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/second");
                  },
                  child: Text(
                    "Segunda Página",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 224, 202),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/third");
                  },
                  child: Text(
                    "Tercera Página",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 224, 202),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  ),
                ),
              ],
            ),
            // Este es el switch para cambiar el tema manualmente
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Tema oscuro"),
                Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(); // Cambia el tema cuando se toca el switch.
                  },
                ),
                Text("Tema claro"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
