import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class CrearServicioPage extends StatefulWidget {
  final Map<String, dynamic>? servicio;
  const CrearServicioPage({super.key, this.servicio});

  @override
  State<CrearServicioPage> createState() => _CrearServicioPageState();
}

class _CrearServicioPageState extends State<CrearServicioPage> {
  final _formKey = GlobalKey<FormState>();
  static const _primary = Color(0xFF19382F);
  bool _isLoading = false;

  late TextEditingController _nombreCtrl;
  late TextEditingController _microserviciosCtrl;
  String _tipo = 'Cancha';

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _nombreCtrl = TextEditingController(text: s?['nombre'] ?? '');
    final ms = s?['microservicios'] as List?;
    _microserviciosCtrl = TextEditingController(text: ms?.join(', ') ?? '');
    _tipo = s?['tipo'] ?? 'Cancha';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _microserviciosCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final espacioId = prefs.getString('espacio_id') ?? '';

      final uri = widget.servicio == null
          ? Uri.parse('${Config.baseUrl}/api/$espacioId')
          : Uri.parse('${Config.baseUrl}/api/${widget.servicio!['_id']}');

      final msList = _microserviciosCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      var request = http.MultipartRequest(widget.servicio == null ? 'POST' : 'PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre'] = _nombreCtrl.text.trim();
      request.fields['tipo'] = _tipo;
      request.fields['microservicios'] = jsonEncode(msList);
      // Horario vacío por defecto — se configura luego desde Gestión de Horarios
      request.fields['horarios'] = jsonEncode([]);
      request.fields['diasAbierto'] = jsonEncode([]);

      final resp = await request.send();
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        _snack(widget.servicio == null ? '¡Servicio creado!' : '¡Servicio actualizado!');
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack('Error al guardar');
      }
    } catch (_) {
      _snack('Error de conexión');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.servicio == null ? 'Nuevo Servicio' : 'Editar Servicio',
          style: GoogleFonts.sansita(color: _primary, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _primary,
      ),
      body: Stack(children: [
        Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              // Info destacada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    'Los horarios y precios se configuran desde "Gestión de Horarios" en el panel de reservas.',
                    style: GoogleFonts.sansita(fontSize: 13, color: Colors.blue.shade700),
                  )),
                ]),
              ),
              const SizedBox(height: 28),

              // Nombre
              _buildSectionHeader(Icons.sports_soccer_rounded, 'Información Principal'),
              const SizedBox(height: 16),
              _buildInput(controller: _nombreCtrl, label: 'Nombre del servicio', hint: 'Ej: Cancha Sintética Pro', icon: Icons.sports_rounded),
              const SizedBox(height: 20),

              // Tipo
              Text('Tipo de servicio', style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                style: GoogleFonts.sansita(fontSize: 16, color: _primary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded, color: _primary.withValues(alpha: 0.4), size: 20),
                  filled: true,
                  fillColor: _primary.withValues(alpha: 0.03),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2), width: 1.5)),
                ),
                items: ['Cancha', 'Piscina', 'Ecuavoley', 'Otro']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.sansita(color: _primary))))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader(Icons.auto_awesome_rounded, 'Extras Incluidos'),
              const SizedBox(height: 16),
              _buildInput(
                controller: _microserviciosCtrl,
                label: 'Extras (separados por coma)',
                hint: 'Ej: Chalecos, Balón, Agua',
                icon: Icons.add_task_rounded,
                maxLines: 2,
                required: false,
              ),

              const SizedBox(height: 48),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: _primary.withValues(alpha: 0.4),
                  ),
                  onPressed: _isLoading ? null : _guardar,
                  child: Text('Guardar Servicio', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        if (_isLoading)
          Container(color: Colors.white.withValues(alpha: 0.6), child: const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)))),
      ]),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: _primary, size: 20),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
    ]);
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.sansita(fontSize: 16, color: _primary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: _primary.withValues(alpha: 0.4), size: 20),
          filled: true,
          fillColor: _primary.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary.withValues(alpha: 0.2), width: 1.5)),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
      ),
    ]);
  }
}