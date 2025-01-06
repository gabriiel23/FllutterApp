import 'package:flutter/material.dart';
import 'package:flutterapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustes Generales',
              style: TextStyle(
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
                color: Colors.blue.shade700,
              ),
              title: const Text('Tema'),
              subtitle: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? 'Oscuro'
                    : 'Claro',
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
              leading: Icon(Icons.notifications, color: Colors.blue.shade700),
              title: const Text('Notificaciones'),
              subtitle: const Text('Personaliza las notificaciones'),
              onTap: () {
                // Acción al pulsar
                print('Abrir configuraciones de notificaciones');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.language, color: Colors.blue.shade700),
              title: const Text('Idioma'),
              subtitle: const Text('Selecciona el idioma preferido'),
              onTap: () {
                // Acción al pulsar
                print('Abrir configuraciones de idioma');
              },
            ),
          ],
        ),
      ),
    );
  }
}
