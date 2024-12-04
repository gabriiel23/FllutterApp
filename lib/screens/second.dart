import 'package:flutter/material.dart';

class Second extends StatelessWidget {
  const Second({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Proximo",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 232, 224, 202),
                    fontSize: 40,
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
                  "Puede ir las canchas",
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
                )
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                  40.0), // Ajusta el valor para el redondeo deseado
              child: Image.asset(
                'assets/columpio.gif',
                width: 280, // Opcional: Ajusta el ancho de la imagen
                height: 280, // Opcional: Ajusta la altura de la imagen
                fit: BoxFit
                    .cover, // Opcional: Ajusta cómo se ajusta la imagen al contenedor
              ),
            ),
            Column(
              children: [
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
                )
              ],
            )
          ],
        ),
      ), // Scaffold
    ); // MaterialApp
  }
}
