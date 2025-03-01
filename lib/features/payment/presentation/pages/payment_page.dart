import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class PaymentPage extends StatefulWidget {
  @override
  _Payment createState() => _Payment();
}

class _Payment extends State<PaymentPage> {
  // Variables para manejar la imagen seleccionada
  File? _imageFile;
  Uint8List? _imageBytes;

  // Método para seleccionar la imagen del comprobante de pago
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Si es web, leer la imagen como bytes
        _imageBytes = await pickedFile.readAsBytes();
      } else {
        // Si no es web, usar File
        _imageFile = File(pickedFile.path);
      }
      setState(() {});

      // Mostrar SnackBar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Comprobante subido correctamente"),
          duration: Duration(seconds: 2), // Duración de 2 segundos
        ),
      );

      // Redirigir a /home después de 2 segundos
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pago", style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Elija su método de pago",
              style: GoogleFonts.sansita(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          // TabBar con tres métodos de pago
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: "Ahorita"),
                    Tab(text: "De una"),
                    Tab(text: "3. Paypal"),
                  ],
                  indicatorColor: Color(0xFF19382F),
                ),
                Container(
                  height: 400, // Ajusta el tamaño del contenido debajo del TabBar
                  child: TabBarView(
                    children: [
                      // Primer Tab (Ahorita)
                      _buildTabContent("Ahorita"),
                      // Segundo Tab (De una)
                      _buildTabContent("De una"),
                      // Tercer Tab (Paypal)
                      _buildTabContent("Paypal"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función que construye el contenido de cada Tab
  Widget _buildTabContent(String paymentMethod) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Imagen representativa del método de pago
        Image.network(
          'https://pbs.twimg.com/media/F4T3sRAWcAIFwEG?format=jpg&name=large', // Asegúrate de tener estas imágenes en la carpeta 'assets/images'
          width: 200,
          height: 200,
        ),
        SizedBox(height: 20),
        // Apartado para cargar el comprobante
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Título para cargar comprobante
              Text(
                "Cargar comprobante del pago",
                style: GoogleFonts.sansita(fontSize: 18),
              ),
              SizedBox(height: 20),
              // Botón para seleccionar la imagen
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Seleccionar imagen",
                  style: GoogleFonts.sansita(color: Colors.black),
                ),
              ),
              SizedBox(height: 20),
              // Mostrar la imagen seleccionada si existe
              if (_imageBytes != null)
                Image.memory(_imageBytes!, width: 200, height: 200),
              if (_imageFile != null)
                Image.file(_imageFile!, width: 200, height: 200),
              if (_imageBytes == null && _imageFile == null)
                Text("No se ha seleccionado ninguna imagen",
                    style: GoogleFonts.sansita(color: Colors.grey.shade800)),
            ],
          ),
        ),
      ],
    );
  }
}