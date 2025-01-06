import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Importamos google_fonts
import 'package:flutterapp/theme/theme_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<String> _routes = ['/second', '/third'];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CanchAPP",
          style: GoogleFonts.bebasNeue( // Fuente moderna y deportiva
            textStyle: const TextStyle(fontSize: 28),
          ),
        ),
      ),
      body: Center( // Usamos Center para centrar el contenido vertical y horizontalmente
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ajustamos el tamaño para centrado vertical
            children: [
              Text(
                "CanchAPP",
                style: GoogleFonts.bebasNeue(
                  textStyle: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 84, 26),
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 128, 130, 127),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Espaciado entre los textos
              Text(
                "Reserva tu cancha en segundos",
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 40), // Espaciado antes de la imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(40.0),
                child: Image.asset(
                  'assets/fubol.gif',
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
      
      

    );
  }
}
