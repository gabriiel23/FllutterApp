import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto de perfil
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://via.placeholder.com/150', // URL de imagen falsa
              ),
            ),
            const SizedBox(height: 20),
            // Nombre del usuario
            Text(
              'Nombre del Usuario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 5),
            // Correo del usuario
            Text(
              'usuario@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            // Información del perfil
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue.shade700),
              title: const Text('Teléfono'),
              subtitle: const Text('+1 234 567 890'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue.shade700),
              title: const Text('Dirección'),
              subtitle: const Text('123 Calle Principal, Ciudad, País'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue.shade700),
              title: const Text('Miembro desde'),
              subtitle: const Text('Enero 2023'),
            ),
            const Divider(),
            // Botón para editar perfil
            ElevatedButton.icon(
              onPressed: () {
                // Acción para editar perfil
                print('Editar perfil');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
