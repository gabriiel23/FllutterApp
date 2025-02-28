import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:flutterapp/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'jugador'; // Valor por defecto
  bool _isPasswordVisible = false;

void _register() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Las contraseñas no coinciden')),
    );
    return;
  }

  try {
    final response = await _authService.registerUser(
      _nameController.text, // nombre
      _emailController.text, // email
      _passwordController.text, // password
      _selectedRole, // rol
      _phoneController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['mensaje'])),
    );

    // Navegar a la pantalla de login después de registrarse
    Navigator.pushReplacementNamed(context, '/login');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF19382F), Color(0xFF295C4E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Icon(Icons.sports_soccer, size: 100, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'Regístrate',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _nameController, 'Nombre completo', Icons.person),
                  const SizedBox(height: 20),
                  _buildTextField(_emailController, 'Correo electrónico',
                      Icons.email, TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildTextField(_phoneController, 'Teléfono', Icons.phone,
                      TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildDropdownRole(),
                  const SizedBox(height: 20),
                  _buildPasswordField(_passwordController, 'Contraseña'),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                      _confirmPasswordController, 'Confirmar contraseña'),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      backgroundColor: const Color(0xFF19382F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Registrarse',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta?  ',
                          style: GoogleFonts.sansita(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Text(
                          'Inicia Sesión',
                          style: GoogleFonts.sansita(color: Colors.blue),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.black),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownRole() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        items: const [
          DropdownMenuItem(value: 'jugador', child: Text('Jugador')),
          DropdownMenuItem(value: 'dueño', child: Text('Dueño')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedRole = value!;
          });
        },
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock, color: Colors.black),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
      ),
    );
  }
}
