import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Perfil",
          style: GoogleFonts.sansita(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF19382F),
        actions: [  // Aquí agregamos el PopupMenuButton
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'Login':
                  Navigator.pushNamed(context, '/login');
                  break;
                case 'Configuración':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'Registro':
                  Navigator.pushNamed(context, '/registration');
                  break;
                case 'Cerrar sesión':
                  Navigator.pushReplacementNamed(context, '/logout');
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Login', 'Configuración', 'Registro', 'Cerrar sesión'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: GoogleFonts.sansita(),
                  ),
                );
              }).toList();
            },
            icon: const Icon(
              Icons.menu_sharp,
              color: Colors.white,
            ),
          ),
        ],
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
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRMSGTtrTDtuCpVMqlcS8XLV61ORiQmOSCJUQ&s', // URL de imagen falsa
              ),
            ),
            const SizedBox(height: 20),
            // Nombre del usuario
            Text(
              'Nombre del Usuario',
              style: GoogleFonts.sansita(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            // Correo del usuario
            Text(
              'usuario@example.com',
              style: GoogleFonts.sansita(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            // Información del perfil
            ListTile(
              leading: Icon(Icons.phone, color: const Color(0xFF19382F)),
              title: Text(
                'Teléfono',
                style: GoogleFonts.sansita(),  // Fuente aplicada al título
              ),
              subtitle: Text(
                '+1 234 567 890',
                style: GoogleFonts.sansita(),  // Fuente aplicada al subtítulo
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: const Color(0xFF19382F)),
              title: Text(
                'Dirección',
                style: GoogleFonts.sansita(),
              ),
              subtitle: Text(
                '123 Calle Principal, Ciudad, País',
                style: GoogleFonts.sansita(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.calendar_today, color: const Color(0xFF19382F)),
              title: Text(
                'Miembro desde',
                style: GoogleFonts.sansita(),
              ),
              subtitle: Text(
                'Enero 2023',
                style: GoogleFonts.sansita(),
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            // Botón para editar perfil
            ElevatedButton.icon(
              onPressed: () {
                // Acción para editar perfil
                print('Editar perfil');
              },
              icon: const Icon(Icons.edit),
              label: Text(
                'Editar Perfil',
                style: GoogleFonts.sansita(color: Colors.white),  // Fuente aplicada al texto del botón
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF19382F),
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
