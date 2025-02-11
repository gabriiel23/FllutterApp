import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class NewGroupPage extends StatefulWidget {
  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  List<String> _players = [];
  List<Map<String, String>> _allPlayers = []; // Lista de jugadores con ID y nombre

  final String apiUrl = "http://localhost:3000/api/grupo"; // API de grupos
  final String playersApiUrl = "http://localhost:3000/api/usuarios"; // API de jugadores

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    try {
      var response = await http.get(Uri.parse(playersApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allPlayers = data.map((player) {
            return {
              "id": player["_id"].toString(),
              "nombre": player["nombre"].toString()
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la lista de jugadores')),
      );
    }
  }

  Future<void> _createGroup() async {
    String groupName = _groupNameController.text;
    String groupDescription = _groupDescriptionController.text;

    if (groupName.isEmpty || groupDescription.isEmpty || _players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": groupName,
          "descripcion": groupDescription,
          "integrantes": _players, // Enviar IDs de jugadores
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo creado exitosamente')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el grupo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión con el servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Nuevo Grupo", style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nombre del Grupo", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2A5B4E),
                hintText: "Escribe el nombre del grupo",
                hintStyle: GoogleFonts.sansita(color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Descripción del Grupo", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _groupDescriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2A5B4E),
                hintText: "Escribe una breve descripción",
                hintStyle: GoogleFonts.sansita(color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Seleccionar Jugadores", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _allPlayers
                    .where((player) => player["nombre"]!.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                    .map((player) => player["nombre"]!);
              },
              onSelected: (String selectedPlayer) {
                setState(() {
                  var player = _allPlayers.firstWhere((p) => p["nombre"] == selectedPlayer);
                  if (!_players.contains(player["id"])) {
                    _players.add(player["id"]!);
                  }
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF2A5B4E),
                    hintText: "Buscar jugador...",
                    hintStyle: GoogleFonts.sansita(color: Colors.white),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            _players.isNotEmpty
                ? Column(
                    children: _players.map((playerId) {
                      String playerName = _allPlayers.firstWhere((p) => p["id"] == playerId)["nombre"]!;
                      return ListTile(
                        tileColor: Colors.grey.shade300,
                        title: Text(playerName, style: TextStyle(color: Colors.black)),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _players.remove(playerId);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  )
                : Text("No hay jugadores agregados.", style: GoogleFonts.sansita(color: const Color(0xFF19382F))),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 40, 84, 72),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Crear Grupo", style: GoogleFonts.sansita(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
