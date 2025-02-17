import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class NewCanchaPage extends StatefulWidget {
  @override
  _NewCanchaPageState createState() => _NewCanchaPageState();
}

class _NewCanchaPageState extends State<NewCanchaPage> {
  final _canchaNameController = TextEditingController();
  final _canchaDescriptionController = TextEditingController();
  final _canchaDireccionController = TextEditingController();
  double _canchaRating = 3.0; // Valor predeterminado de calificación
  String? _selectedTipoServicio;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  List<String> tiposServicios = [
    'sintética',
    'básquet',
    'vóley',
    'fútbol',
    'tenis',
    'piscina',
    'otros'
  ];

  Future<void> _pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  Future<void> _crearCancha() async {
    if (_canchaNameController.text.isEmpty ||
        _canchaDescriptionController.text.isEmpty ||
        _canchaDireccionController.text.isEmpty ||
        _selectedTipoServicio == null) {
      _mostrarAlerta('Error', 'Por favor, completa todos los campos.');
      return;
    }

    var url = Uri.parse('http://localhost:3000/api/canchas');

    Map<String, dynamic> canchaData = {
      "nombre": _canchaNameController.text,
      "direccion": _canchaDireccionController.text,
      "descripcion": _canchaDescriptionController.text,
      "disponible": true,
      "calificacion": _canchaRating,
      "servicio": _selectedTipoServicio,
      "imagenes": _image != null ? [_image!.path] : [],
    };

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(canchaData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancha creada con éxito')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _mostrarAlerta('Error', 'No se pudo crear la cancha.');
      }
    } catch (error) {
      _mostrarAlerta(
          'Error de conexión', 'No se pudo conectar con el servidor.');
    }
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Nueva Cancha",
            style: GoogleFonts.sansita(color: Colors.white)),
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
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Color(0xFF2A5B4E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: _image == null
                        ? Center(
                            child: Text(
                              "Toca aquí para seleccionar una imagen",
                              style: GoogleFonts.sansita(color: Colors.white),
                              textAlign: TextAlign.center,
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
              _buildTextField("Nombre", _canchaNameController),
              SizedBox(height: 20),
              _buildTextField("Dirección", _canchaDireccionController),
              SizedBox(height: 20),
              _buildTextField("Descripción", _canchaDescriptionController,
                  maxLines: 4),
              SizedBox(height: 20),
              _buildRatingBar(),
              SizedBox(height: 20),
              _buildDropdown("Tipo de Cancha", tiposServicios, (String? value) {
                setState(() {
                  _selectedTipoServicio = value;
                });
              }),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _crearCancha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF285448),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text("Crear Cancha",
                      style: GoogleFonts.sansita(
                          fontSize: 18, color: Colors.white)),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF2A5B4E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: _selectedTipoServicio,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child:
                  Text(option, style: GoogleFonts.sansita(color: Colors.black)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
              color: Colors.white), // Hace que el texto escrito sea blanco
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF2A5B4E),
            hintText: "Escribe $label",
            hintStyle:
                TextStyle(color: Colors.grey.shade200), // Color blanco para el hintText
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Calificación",
            style:
                GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        RatingBar.builder(
          initialRating: _canchaRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            setState(() {
              _canchaRating = rating;
            });
          },
        ),
      ],
    );
  }
}
