import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de agregar esta dependencia si la usas
import 'routes/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configuración de la animación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Redirigir después de 4 segundos
    Future.delayed(const Duration(seconds: 4)).then(
      (_) => Navigator.pushReplacementNamed(context, Routes.home),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo dinámico
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade800.withOpacity(_animation.value),
                      Colors.blue.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          // Contenido principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    Icons.sports_soccer,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Texto estilizado
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Canchas UIDE',
                    style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Actívate, vive saludable',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Indicador de carga
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
