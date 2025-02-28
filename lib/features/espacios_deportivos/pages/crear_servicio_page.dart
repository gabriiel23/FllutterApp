import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CrearServicioPage extends StatefulWidget {
  @override
  _CrearServicioFormState createState() => _CrearServicioFormState();
}

class _CrearServicioFormState extends State<CrearServicioPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '', tipo = '';
  List<Map<String, dynamic>> horarios = [];
  File? imagenFile;
  Uint8List? imagenBytes;

  TextEditingController horarioInicioController = TextEditingController();
  TextEditingController horarioFinController = TextEditingController();
  TextEditingController precioController = TextEditingController();
  bool disponible = true;

  // Seleccionar una imagen desde la galería
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

  // Agregar un nuevo horario
  void agregarHorario() {
    if (horarioInicioController.text.isNotEmpty &&
        horarioFinController.text.isNotEmpty &&
        precioController.text.isNotEmpty) {
      setState(() {
        horarios.add({
          'inicio': horarioInicioController.text.trim(),
          'fin': horarioFinController.text.trim(),
          'precio': double.parse(precioController.text),
          'disponible': disponible
        });
        horarioInicioController.clear();
        horarioFinController.clear();
        precioController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltan campos en el horario')),
      );
    }
  }

  // Crear el servicio y enviar al backend
  Future<void> crearServicio() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Validar que se hayan agregado horarios
    if (horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes agregar al menos un horario')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? espacioId = prefs.getString('espacio_id');
    if (userId == null || espacioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario o espacio no autenticado')),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://back-canchapp.onrender.com/api/$espacioId'),
    );

    request.fields['nombre'] = nombre;
    request.fields['tipo'] = tipo;
    request.fields['horarios'] = json.encode(horarios); // Enviar horarios como JSON

    if (!kIsWeb && imagenFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenFile!.path),
      );
    } else if (kIsWeb && imagenBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('imagen', imagenBytes!, filename: 'imagen.png'),
      );
    }

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Servicio creado con éxito')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el servicio')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Servicio"),
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
                _buildTextField("Nombre del Servicio", "Ej: Cancha de fútbol", (value) => nombre = value!),
                _buildDropdownField("Tipo de Servicio", ["Cancha", "Piscina", "Ecuavoley", "Otro"], (value) => tipo = value!),
                _buildTextField("Horario Inicio", "Ej: 08:00", (value) => {}, controller: horarioInicioController),
                _buildTextField("Horario Fin", "Ej: 09:00", (value) => {}, controller: horarioFinController),
                _buildTextField("Precio", "Ej: 10.00", (value) => {}, controller: precioController, keyboardType: TextInputType.number),
                SwitchListTile(
                  title: Text("Disponible"),
                  value: disponible,
                  onChanged: (value) {
                    setState(() {
                      disponible = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: agregarHorario,
                  child: Text("Agregar Horario"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                SizedBox(height: 16),
                // Mostrar horarios añadidos
                Column(
                  children: horarios.map((h) => Text("${h['inicio']} - ${h['fin']} (\$${h['precio']})")).toList(),
                ),
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
                    onPressed: crearServicio,
                    child: Text("Crear Servicio", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      backgroundColor: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Campo de texto para entradas
  Widget _buildTextField(String label, String hint, Function(String?) onSaved, {TextEditingController? controller, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        TextFormField(
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder()),
          keyboardType: keyboardType,
          validator: (value) => value!.isEmpty ? "Este campo es obligatorio" : null,
          onSaved: onSaved,
          controller: controller,
        ),
        SizedBox(height: 12),
      ],
    );
  }

  // Campo de selección para dropdown
  Widget _buildDropdownField(String label, List<String> items, Function(String?) onSaved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        DropdownButtonFormField<String>(
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {},
          validator: (value) => value == null ? "Este campo es obligatorio" : null,
          onSaved: onSaved,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}