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
              Tab(icon: Icon(Icons.person, color: Colors.grey), text: "Jugadores"),
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
    final response = await http.get(Uri.parse('https://back-canchapp.onrender.com/api/jugadores'));
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    player['posicion'][0], // Muestra "P" o "J"
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  "Edad: ${player['edad']} años | Estatura: ${player['estatura']} cm",
                  style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Posición: ${player['posicion']}", style: GoogleFonts.sansita()),
                    const SizedBox(height: 4),
                    Text(
                      "Atributos: Tiro ${player['atributos']['Tiro']}, Regate ${player['atributos']['Regate']}, Pase ${player['atributos']['Pase']}",
                      style: GoogleFonts.sansita(fontSize: 14),
                    ),
                  ],
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
    final response = await http.get(Uri.parse('https://back-canchapp.onrender.com/api/grupos'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar grupos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.greenAccent,
                  child: Icon(Icons.group, color: Colors.white),
                ),
                title: Text(
                  group['nombre'],
                  style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group['descripcion'], style: GoogleFonts.sansita(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      "Integrantes: ${group['integrantes'].length}",
                      style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
