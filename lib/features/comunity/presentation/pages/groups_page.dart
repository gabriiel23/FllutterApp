import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Groups extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF19382F),
          title: Text(
            "Comunidad",
            style: GoogleFonts.sansita(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                  icon: Icon(Icons.person, color: Colors.grey),
                  text: "Jugadores"),
              Tab(icon: Icon(Icons.group, color: Colors.grey), text: "Grupos"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(
          children: [
            PlayersTab(),
            GroupsTab(),
          ],
        ),
      ),
    );
  }
}

class PlayersTab extends StatefulWidget {
  const PlayersTab({super.key});

  @override
  _PlayersTabState createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  Future<List<dynamic>> fetchPlayers() async {
    final response =
        await http.get(Uri.parse('https://back-canchapp.onrender.com/api/jugadores'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar jugadores');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchPlayers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay jugadores disponibles"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var player = snapshot.data![index];

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    player['posicion']?.toString()[0] ?? '?', // Evita null
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['usuario'] != null &&
                              player['usuario']['nombre'] != null
                          ? "Jugador: ${player['usuario']['nombre']}"
                          : "Jugador: Desconocido",
                      style: GoogleFonts.sansita(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Edad: ${player['edad'] ?? 'N/A'} años | Estatura: ${player['estatura'] ?? 'N/A'} cm",
                      style: GoogleFonts.sansita(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Posición: ${player['posicion'] ?? 'Desconocida'}",
                        style: GoogleFonts.sansita()),
                    const SizedBox(height: 4),
                    Text(
                      "Atributos: Tiro ${player['atributos']?['Tiro'] ?? 'N/A'}, "
                      "Regate ${player['atributos']?['Regate'] ?? 'N/A'}, "
                      "Pase ${player['atributos']?['Pase'] ?? 'N/A'}",
                      style: GoogleFonts.sansita(fontSize: 14),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Jugador desafiado correctamente")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Desafiar", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  _GroupsTabState createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  Future<List<dynamic>> fetchGroups() async {
    final response = await http
        .get(Uri.parse('https://back-canchapp.onrender.com/api/grupos'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar grupos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay grupos disponibles"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var group = snapshot.data![index];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.greenAccent,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(
                    group['nombre'] ?? "Nombre no disponible",
                    style: GoogleFonts.sansita(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['descripcion'] ?? "Sin descripción",
                          style: GoogleFonts.sansita(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        "Integrantes: ${group['integrantes']?.length ?? 0}",
                        style: GoogleFonts.sansita(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Grupo desafiado correctamente")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Desafiar",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/newGroup');
        },
        backgroundColor: const Color(0xFF19382F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
