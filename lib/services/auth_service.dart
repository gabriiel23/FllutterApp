import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart'; // Agrega esta librería en tu pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000/api'; // Cambia esto por tu URL real

  Future<Map<String, dynamic>> registerUser(String nombre, String email, String password, String rol) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'rol': rol,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error']);
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
      String userRole = decodedToken['rol']; // Ajusta según la estructura de tu JWT
      String userId = decodedToken['id']; // Ajusta según la estructura de tu JWT

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
}