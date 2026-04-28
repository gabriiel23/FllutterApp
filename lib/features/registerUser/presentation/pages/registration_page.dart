import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutterapp/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _nacionalidadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  final Color _primaryDeep = const Color(0xFF19382F);

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  void _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Nombre, Email y Contraseña son obligatorios');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerUser(
        _nameController.text,
        _apellidosController.text,
        _nacionalidadController.text,
        _emailController.text,
        _passwordController.text,
        _phoneController.text,
        _avatarImage,
      );
      setState(() => _isLoading = false);
      _showProfilePrompt();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.sansita()),
        backgroundColor: _primaryDeep,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showProfilePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¡Registro exitoso! 🎉',
          style: GoogleFonts.sansita(
              fontWeight: FontWeight.bold, color: _primaryDeep),
        ),
        content: Text(
          '¿Quieres configurar tu perfil de jugador (tipo Carta FIFA) en este momento?',
          style: GoogleFonts.sansita(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text('Más tarde',
                style: GoogleFonts.sansita(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/profilePlayer');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryDeep,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Configurar ahora',
                style: GoogleFonts.sansita(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(),
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  // ── SECCIÓN SUPERIOR: Avatar + Título ─────────────────────────────────────
  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryDeep,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            children: [
              // Botón volver alineado
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2.5),
                        image: _avatarImage != null
                            ? DecorationImage(
                                image: FileImage(_avatarImage!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: _avatarImage == null
                          ? const Icon(Icons.person_rounded,
                              size: 48, color: Colors.white70)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6)
                          ],
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 16, color: _primaryDeep),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Únete a CanchAPP',
                style: GoogleFonts.sansita(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Crea tu cuenta y empieza a jugar',
                style: GoogleFonts.sansita(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECCIÓN FORMULARIO ────────────────────────────────────────────────────
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grupo: Información personal ──
          _buildGroupLabel(Icons.badge_rounded, 'Información personal'),
          const SizedBox(height: 12),
          _buildField(
            controller: _nameController,
            hint: 'Nombres',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _apellidosController,
            hint: 'Apellidos',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _nacionalidadController,
            hint: '¿De dónde eres?',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _phoneController,
            hint: 'Teléfono',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 28),

          // ── Grupo: Acceso ──
          _buildGroupLabel(Icons.lock_rounded, 'Datos de acceso'),
          const SizedBox(height: 12),
          _buildField(
            controller: _emailController,
            hint: 'Correo electrónico',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _passwordController,
            hint: 'Contraseña',
            isVisible: _isPasswordVisible,
            onToggle: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: 'Confirmar contraseña',
            isVisible: _isConfirmPasswordVisible,
            onToggle: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          const SizedBox(height: 36),

          // ── Botón principal ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryDeep.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Crear cuenta',
                      style: GoogleFonts.sansita(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Link login ──
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.sansita(
                      fontSize: 15, color: Colors.grey.shade500),
                  children: [
                    const TextSpan(text: '¿Ya tienes una cuenta? '),
                    TextSpan(
                      text: 'Inicia sesión',
                      style: GoogleFonts.sansita(
                        color: _primaryDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS AUXILIARES ────────────────────────────────────────────────────
  Widget _buildGroupLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _primaryDeep),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.sansita(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _primaryDeep,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sansita(
              color: _primaryDeep.withValues(alpha: 0.35), fontSize: 15),
          prefixIcon:
              Icon(icon, color: _primaryDeep.withValues(alpha: 0.5), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sansita(
              color: _primaryDeep.withValues(alpha: 0.35), fontSize: 15),
          prefixIcon: Icon(Icons.lock_rounded,
              color: _primaryDeep.withValues(alpha: 0.5), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _primaryDeep.withValues(alpha: 0.4),
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
