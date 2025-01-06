import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de agregar esta dependencia si la usas
import 'routes/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Estado asociado al SplashScreen, manejando animaciones y lógica
// Un Ticker es un componente que "marca el tiempo", proporcionando un flujo continuo de valores en función del tiempo transcurrido.
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controlador de animación
  late Animation<double> _animation; // Animación basada en un valor de doble precisión

  @override
  void initState() {
    super.initState();

    // Configuración del AnimationController
    _controller = AnimationController(
      vsync: this, // vsync optimiza el rendimiento de la animación
      duration: const Duration(seconds: 2), // Duración de la animación
    )..forward(); // Inicia la animación automáticamente al inicializar

    // Configuración de la animación con una curva de entrada/salida suave
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Redirige automáticamente a la página principal después de 4 segundos
    Future.delayed(const Duration(seconds: 4)).then(
      (_) => Navigator.pushReplacementNamed(context, Routes.home), // Navegación a la pantalla principal
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera recursos del controlador de animación
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo dinámico que cambia con la animación
          AnimatedBuilder(
            animation: _animation, // Vincula la animación al AnimatedBuilder
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade800.withOpacity(_animation.value), // Ajusta la opacidad dinámicamente
                      Colors.blue.shade300, // Color de fondo complementario
                    ],
                    begin: Alignment.topLeft, // Dirección del degradado
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          // Contenido principal de la pantalla
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente los elementos
              children: [
                // Logo con animación de escala
                ScaleTransition(
                  scale: _animation, // Escala proporcional al progreso de la animación
                  child: Icon(
                    Icons.sports_score_rounded, // Ícono representativo
                    size: 100, // Tamaño del ícono
                    color: Colors.white, // Color del ícono
                  ),
                ),
                const SizedBox(height: 20), // Espaciado entre el ícono y el texto
                // Texto principal con animación de aparición gradual
                FadeTransition(
                  opacity: _animation, // Opacidad vinculada a la animación
                  child: Text(
                    'Canchas UIDE', // Título de la aplicación
                    style: GoogleFonts.lato( // Fuente personalizada con Google Fonts
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Espaciado entre textos
                // Subtítulo con animación de aparición gradual
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Actívate, vive saludable', // Lema de la aplicación
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70, // Color más tenue para el subtítulo
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Indicador de carga ubicado al final de la pantalla
          Positioned(
            bottom: 50, // Posición desde el fondo de la pantalla
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white, // Indicador de carga en blanco
              ),
            ),
          ),
        ],
      ),
    );
  }
}
