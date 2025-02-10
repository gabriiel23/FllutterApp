import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class NewCanchaPage extends StatefulWidget {
  @override
  _NewCanchaPageState createState() => _NewCanchaPageState();
}

class _NewCanchaPageState extends State<NewCanchaPage> {
  final _canchaNameController = TextEditingController();
  final _canchaDescriptionController = TextEditingController();
  final _canchaRatingController = TextEditingController();
  List<String> _selectedServices = [];
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  List<String> opcionesServicios = [
    'Piscina', 'Iluminación', 'Parqueadero'
  ];

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Nueva Cancha", style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Cargar Imagen de la Cancha",
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
                      color: const Color.fromARGB(255, 42, 91, 78),
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
              Text("Nombre", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: _canchaNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2A5B4E),
                  hintText: "Escribe el nombre de la cancha",
                  hintStyle: GoogleFonts.sansita(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
              Text("Descripción", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: _canchaDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2A5B4E),
                  hintText: "Escribe una breve descripción",
                  hintStyle: GoogleFonts.sansita(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
              Text("Calificación", style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: _canchaRatingController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2A5B4E),
                  hintText: "Escribe una calificación del 1 al 5",
                  hintStyle: GoogleFonts.sansita(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
              CanchaServiceSelector(
                servicios: _selectedServices,
                opcionesServicios: opcionesServicios,
                onServiceChanged: (newServices) {
                  setState(() {
                    _selectedServices = newServices;
                  });
                },
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    String canchaName = _canchaNameController.text;
                    String canchaDescription = _canchaDescriptionController.text;
                    if (canchaName.isNotEmpty && canchaDescription.isNotEmpty && _selectedServices.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cancha creada: $canchaName')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Por favor, completa todos los campos')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 40, 84, 72), padding: EdgeInsets.only(right: 40, left: 40, top: 12, bottom: 12)),
                  child: Text("Crear Cancha", style: GoogleFonts.sansita(fontSize: 18, color: Colors.white)),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class CanchaServiceSelector extends StatelessWidget {
  final List<String> servicios;
  final List<String> opcionesServicios;
  final Function(List<String>) onServiceChanged;

  CanchaServiceSelector({required this.servicios, required this.opcionesServicios, required this.onServiceChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Servicios:', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Wrap(
            spacing: 6.0,
            children: opcionesServicios.map((servicio) {
              return ChoiceChip(
                label: Text(servicio),
                selected: servicios.contains(servicio),
                onSelected: (selected) {
                  List<String> updatedServices = List.from(servicios);
                  selected ? updatedServices.add(servicio) : updatedServices.remove(servicio);
                  onServiceChanged(updatedServices);
                },
                selectedColor: Color(0xFF2A5B4E),
                labelStyle: TextStyle(color: servicios.contains(servicio) ? Colors.white : Colors.black),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
