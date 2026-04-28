import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart'; // Agrega esta librería en tu pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class AuthService {
  final String baseUrl = '${Config.baseUrl}/api'; // Cambia esto por tu URL real

  Future<Map<String, dynamic>> registerUser(
      String nombre,
      String apellidos,
      String nacionalidad,
      String email,
      String password,
      String telefono,
      File? avatar) async {
    
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/registro'));
    
    request.fields['nombre'] = nombre;
    request.fields['apellidos'] = apellidos;
    request.fields['nacionalidad'] = nacionalidad;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['telefono'] = telefono;
    
    if (avatar != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      
      // Auto-login con el token recibido
      if (responseData.containsKey('token')) {
        final String token = responseData['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String userRole = decodedToken['rol']; 
        String userId = decodedToken['id']; 

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', token);
        await prefs.setString('userRol', userRole);
        await prefs.setString('userId', userId);
      }
      
      return responseData;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error desconocido al registrar');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final String token = responseData['token'];

      // Decodificar el token para extraer el rol y el ID del usuario
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String userRole =
          decodedToken['rol']; // Ajusta según la estructura de tu JWT
      String userId =
          decodedToken['id']; // Ajusta según la estructura de tu JWT

      // Guardar el token, rol y ID en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userToken', token);
      await prefs.setString('userRol', userRole);
      await prefs.setString('userId', userId);

      return responseData;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String userId,
      String token,
      String nombre,
      String apellidos,
      String nacionalidad,
      String telefono,
      File? avatar) async {
    
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/usuario/$userId'));
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['nombre'] = nombre;
    request.fields['apellidos'] = apellidos;
    request.fields['nacionalidad'] = nacionalidad;
    request.fields['telefono'] = telefono;
    
    if (avatar != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error desconocido al actualizar usuario');
    }
  }
}
