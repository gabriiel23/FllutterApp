import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Reserves extends StatelessWidget {
  const Reserves({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF19382F),
        title: Text(
          "Tus reservas",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(  // Añadido SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Reservas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Resumen de Reservas",
                  style: GoogleFonts.sansita(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Consulta y administra tus reservas de manera rápida y sencilla.",
                  style: GoogleFonts.sansita(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reservas Pendientes
            Text(
              "Reservas Pendientes",
              style: GoogleFonts.sansita(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '12/12/2024 - 10:00 AM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cancha 1',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '14/12/2024 - 3:00 PM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cancha 2',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reservas Pasadas
            Text(
              "Reservas Pasadas",
              style: GoogleFonts.sansita(
                color: Colors.grey.shade800,
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10/12/2024 - 9:00 AM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Cancha 1',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '11/12/2024 - 5:00 PM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Cancha 2',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '08/12/2024 - 5:00 PM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Cancha 3',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF19382F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '08/12/2024 - 5:00 PM',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Cancha 4',
                    style: GoogleFonts.sansita(
                      color: const Color(0xFF19382F),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
