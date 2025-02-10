import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';

class Groups extends StatelessWidget {
  final List<String> _routes = [
    Routes.newGroupPage, // Home// Eventos
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: Jugadores y Grupos
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF19382F),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment
                .start, // Mantiene el título alineado a la izquierda
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Espaciado vertical del título
                child: Text(
                  "Comunidad",
                  style: GoogleFonts.sansita(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                color: Colors.grey[300],
                height: 1.0,
                thickness: 1.0,
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.person, color: Colors.grey),
                text: "Jugadores",
              ),
              Tab(
                icon: Icon(Icons.group, color: Colors.grey),
                text: "Grupos",
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 16),
            unselectedLabelStyle: TextStyle(fontSize: 14),
          ),
        ),
        body: const TabBarView(
          children: [
            // Contenido para "Jugadores"
            PlayersTab(),
            // Contenido para "Grupos"
            GroupsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navegar a la página de creación de un nuevo grupo
            Navigator.pushNamed(context, Routes.newGroupPage);
          },
          backgroundColor: const Color(0xFF19382F),
          child: const Icon(
            Icons.add,
            color: Colors.white, // Establece el color del ícono a blanco
          ),
        ),
      ),
    );
  }
}

class PlayersTab extends StatelessWidget {
  const PlayersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "En esta podras ver jugadores e invitarlos a tus grupos.",
            style: GoogleFonts.sansita(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://static.independent.co.uk/2022/11/18/09/GettyImages-1401702557%20%281%29.jpg?quality=75&width=1200&auto=webp"),
              ),
              title: Text(
                "Cristiano Messi",
                style: GoogleFonts.sansita(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Jugador de la Liga de Loja",
                style: GoogleFonts.sansita(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Acción para invitar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Invitación enviada a Cristiano Messi",
                            style: TextStyle(
                              fontFamily: 'Sansita',
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19382F),
                    ),
                    child: const Text(
                      "Invitar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Acción para ver detalles
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Detalles de Cristiano Messi",
                            style: TextStyle(
                              fontFamily: 'Sansita',
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text(
                      "Detalles",
                      style: TextStyle(color: Color(0xFF19382F)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grupos a los que perteneces:",
            style: GoogleFonts.sansita(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://cdn.mos.cms.futurecdn.net/5da3GNWTGWu9ybbEJ6YNzJ-1200-80.jpg"),
                // Usa una imagen de ejemplo o un avatar
              ),
              title: Text(
                "Equipo Los Invencibles",
                style: GoogleFonts.sansita(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Miembro desde 2023",
                style: GoogleFonts.sansita(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Invitaciones pendientes:",
            style: GoogleFonts.sansita(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://files.antena2.com/antena2/public/2019-04/supercampeones_1_0.jpg?VersionId=OJmXXp0OmeimR1q7ECRM9o0pXgrE8W3P"),
                // Usa una imagen de ejemplo o un avatar
              ),
              title: Text(
                "Equipo Los Campeones",
                style: GoogleFonts.sansita(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Invitación pendiente",
                style: GoogleFonts.sansita(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Acción para aceptar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Invitación aceptada",
                            style: TextStyle(
                              fontFamily: 'Sansita',
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Aceptar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Acción para rechazar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Invitación rechazada",
                            style: TextStyle(
                              fontFamily: 'Sansita',
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "Rechazar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
