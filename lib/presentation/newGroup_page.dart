import 'dart:io'; // Asegúrate de importar dart:io
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts

class NewGroupPage extends StatefulWidget {
  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  List<String> _players = [];
  XFile? _image; // Almacena la imagen seleccionada

  final ImagePicker _picker = ImagePicker();

  // Función para seleccionar una imagen
  Future<void> _pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Nuevo Grupo", style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F), // Color verde oscuro
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        // Aseguramos que todo el contenido sea desplazable
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opción para cargar una imagen desde el dispositivo
              Center(
                child: Text(
                  "Cargar Imagen del Grupo",
                  style: GoogleFonts.sansita(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                // Centramos el contenedor de la imagen
                child: GestureDetector(
                  onTap:
                      _pickImage, // Llama a la función para seleccionar la imagen
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle, // Hacemos la imagen circular
                      border: Border.all(color: Colors.white),
                    ),
                    child: _image == null
                        ? Center(
                            child: Text(
                              "Toca aquí para seleccionar una imagen",
                              style: GoogleFonts.sansita(
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ClipOval(
                            child: Image.file(
                              File(_image!.path),
                              fit: BoxFit.cover,
                              height: 150,
                              width: 150,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Nombre del Grupo
              Text(
                "Nombre del Grupo",
                style: GoogleFonts.sansita(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey,
                  hintText: "Escribe el nombre del grupo",
                  hintStyle: GoogleFonts.sansita(color: const Color(0xFF19382F), fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Descripción del Grupo
              Text(
                "Descripción del Grupo",
                style: GoogleFonts.sansita(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _groupDescriptionController,
                style: TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey,
                  hintText: "Escribe una breve descripción",
                  hintStyle: GoogleFonts.sansita(color: const Color(0xFF19382F), fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Agregar jugadores
              Text(
                "Agregar Jugadores",
                style: GoogleFonts.sansita(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey,
                  hintText: "Ingresa el nombre del jugador",
                  hintStyle: GoogleFonts.sansita(color: const Color(0xFF19382F), fontWeight: FontWeight.w600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (playerName) {
                  setState(() {
                    if (playerName.isNotEmpty) {
                      _players.add(playerName);
                    }
                  });
                },
              ),
              SizedBox(height: 10),

              // Lista de jugadores
              _players.isNotEmpty
                  ? Column(
                      children: _players.map((player) {
                        return ListTile(
                          title: Text(player,
                              style: TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _players.remove(player);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    )
                  : Text("No hay jugadores agregados.",
                      style: GoogleFonts.sansita(color: const Color(0xFF19382F))),

              SizedBox(height: 30),

              // Botón de acción
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    String groupName = _groupNameController.text;
                    String groupDescription = _groupDescriptionController.text;

                    if (groupName.isNotEmpty &&
                        groupDescription.isNotEmpty &&
                        _players.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Grupo creado: $groupName')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Por favor, completa todos los campos')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19382F),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Crear Grupo",
                    style: GoogleFonts.sansita(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
