import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/presentation/routes/routes.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF19382F),
              Color.fromARGB(255, 41, 92, 78),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tarjeta central
                Card(
                  elevation: 10,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono
                        const Icon(
                          Icons.logout,
                          size: 60,
                          color: Color(0xFF19382F),
                        ),
                        const SizedBox(height: 20),
                        // Mensaje de confirmación
                        Text(
                          '¿Estás seguro de que deseas cerrar sesión?',
                          style: GoogleFonts.sansita(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        // Botón de cerrar sesión
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Routes.login,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Cerrar Sesión',
                            style: GoogleFonts.sansita(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Botón de cancelar
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.home);
                          },
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.sansita(
                              fontSize: 16,
                              color: Colors.blueAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
