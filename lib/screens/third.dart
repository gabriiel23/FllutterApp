import 'package:flutter/material.dart';

class Third extends StatefulWidget {
  const Third({super.key});

  @override
  _ThirdState createState() => _ThirdState();
}

class _ThirdState extends State<Third> {
  // Definimos una variable de estado para contar las veces que el botón es presionado
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(54.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Soldado",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 232, 224, 202),
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0), // Desplazamiento de la sombra
                        blurRadius: 3.0, // Suavidad de la sombra
                        color: Colors.black, // Color de la sombra
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
                        offset: Offset(2.0, 2.0), // Desplazamiento de la sombra
                        blurRadius: 3.0, // Suavidad de la sombra
                        color: const Color.fromARGB(
                            255, 232, 224, 202), // Color de la sombra
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(40.0),
              child: Image.asset(
                'assets/soldado.gif',
                width: 300,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _counter++; // Aumenta el contador cada vez que se presiona el botón
                    });
                  },
                  child: Text(
                    "Incrementar contador",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 232, 224, 202),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16)),
                ),
                SizedBox(height: 16),
                Text(
                  'Contador: $_counter', // Muestra el valor del contador
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/home");
                  },
                  child: Text(
                    "Regresar",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 232, 224, 202),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
