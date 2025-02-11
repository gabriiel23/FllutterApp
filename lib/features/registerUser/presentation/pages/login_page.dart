import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Usuario temporal predefinido
  final String tempEmail = "messi@gmail.com";
  final String tempPassword = "12345";

  void _login() {
    // Compara el correo y la contraseña con el usuario temporal
    if (_emailController.text == tempEmail && _passwordController.text == tempPassword) {
      // print('Iniciando sesión como usuario temporal');
      Navigator.pushNamed(context, Routes.home); // Redirige al home
    } else {
      // Si no coincide, muestra un mensaje de error
      // print('Credenciales incorrectas');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('El correo o la contraseña son incorrectos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF19382F),
                  const Color.fromARGB(255, 41, 92, 78),
                ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Hero(
                    tag: 'logo',
                    child: Icon(
                      Icons.sports_soccer,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Título
                  Text(
                    'Inicia Sesión',
                    style: GoogleFonts.sansita(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Campo de correo electrónico
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.sansita(),
                  ),
                  const SizedBox(height: 20),
                  // Campo de contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.sansita(),
                  ),
                  const SizedBox(height: 40),
                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: _login, // Llama a la función de login
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      backgroundColor: const Color(0xFF19382F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.sansita(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Opción de registro
                  GestureDetector(
                    onTap: () {
                      // Navegar a la ruta de registro
                      Navigator.pushNamed(context, Routes.registration);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Esto ajusta el tamaño del Row al contenido
                      children: [
                        Text(
                          '¿No tienes cuenta?  ',
                          style: GoogleFonts.sansita(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Text(
                          'Registrate',
                          style: GoogleFonts.sansita(
                            color: Colors.blue,
                          ),
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
}
