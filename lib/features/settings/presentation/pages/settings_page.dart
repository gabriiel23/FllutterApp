import 'package:flutter/material.dart';
import 'package:flutterapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.sansita(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF19382F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajustes Generales',
              style: GoogleFonts.sansita(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: const Color(0xFF19382F),
              ),
              title: Text(
                'Tema',
                style: GoogleFonts.sansita(),
              ),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? 'Oscuro'
                    : 'Claro',
                style: GoogleFonts.sansita(),
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: const Color(0xFF19382F),
              ),
              title: Text(
                'Notificaciones',
                style: GoogleFonts.sansita(),
              ),
              subtitle: Text(
                'Personaliza las notificaciones',
                style: GoogleFonts.sansita(),
              ),
              onTap: () {
                // Acción al pulsar
                // print('Abrir configuraciones de notificaciones');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.language,
                color: const Color(0xFF19382F),
              ),
              title: Text(
                'Idioma',
                style: GoogleFonts.sansita(),
              ),
              subtitle: Text(
                'Selecciona el idioma preferido',
                style: GoogleFonts.sansita(),
              ),
              onTap: () {
                // Acción al pulsar
                // print('Abrir configuraciones de idioma');
              },
            ),
          ],
        ),
      ),
    );
  }
}
