import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CrearEspacioDeportivoPage extends StatefulWidget {
  @override
  _CrearEspacioDeportivoPageState createState() => _CrearEspacioDeportivoPageState();
}

class _CrearEspacioDeportivoPageState extends State<CrearEspacioDeportivoPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '', ubicacion = '', descripcion = '';
  File? imagenFile;
  Uint8List? imagenBytes;

  Future<void> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        imagenBytes = await pickedFile.readAsBytes();
      } else {
        imagenFile = File(pickedFile.path);
      }
      setState(() {});
    }
  }

Future<void> crearEspacioDeportivo() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')));
    return;
  }

  var request = http.MultipartRequest(
      'POST', Uri.parse('https://back-canchapp.onrender.com/api/espacio-deportivo'));

  request.fields['nombre'] = nombre;
  request.fields['ubicacion'] = ubicacion;
  request.fields['descripcion'] = descripcion;
  request.fields['propietario'] = userId;

  // Verificar si hay una imagen y enviarla correctamente
  if (!kIsWeb && imagenFile != null) {
    request.files
        .add(await http.MultipartFile.fromPath('imagen', imagenFile!.path));
  } else if (kIsWeb && imagenBytes != null) {
    request.files.add(http.MultipartFile.fromBytes(
      'imagen', imagenBytes!,
      filename: 'imagen.png', // Nombre de archivo para la versión web
    ));
  }

  var response = await request.send();

  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Espacio Deportivo creado con éxito')));
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el espacio deportivo')));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nuevo Espacio Deportivo", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Nombre", "Ej: Polideportivo Quito", (value) => nombre = value!),
                _buildTextField("Ubicación", "Ej: Av. Amazonas 123", (value) => ubicacion = value!),
                _buildTextField("Descripción", "Describe el espacio deportivo...", (value) => descripcion = value!, maxLines: 3),
                SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      if (imagenBytes != null) Image.memory(imagenBytes!, height: 150),
                      if (imagenFile != null) Image.file(imagenFile!, height: 150),
                      if (imagenBytes == null && imagenFile == null)
                        Text("No se ha seleccionado imagen", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: seleccionarImagen,
                        icon: Icon(Icons.image),
                        label: Text("Seleccionar Imagen"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: crearEspacioDeportivo,
                    child: Text("Crear Espacio Deportivo", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20), backgroundColor: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String?) onSaved, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600)),
        TextFormField(
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder()),
          maxLines: maxLines,
          validator: (value) => value!.isEmpty ? "Este campo es obligatorio" : null,
          onSaved: onSaved,
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
