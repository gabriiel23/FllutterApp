import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class CrearNoticiaPage extends StatefulWidget {
  final String espacioId;
  const CrearNoticiaPage({super.key, required this.espacioId});

  @override
  State<CrearNoticiaPage> createState() => _CrearNoticiaPageState();
}

class _CrearNoticiaPageState extends State<CrearNoticiaPage> {
  final Color _primaryDeep = const Color(0xFF19382F);
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  String _tipo = 'noticia';
  XFile? _imagenFile;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _imagenFile = f);
  }

  Future<void> _pickDate(bool isInicio) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? (_fechaInicio ?? now) : (_fechaFin ?? (_fechaInicio ?? now).add(const Duration(days: 1))),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: _primaryDeep, onPrimary: Colors.white, surface: Colors.white, onSurface: _primaryDeep)), 
        child: child!
      ),
    );
    if (picked != null) setState(() => isInicio ? _fechaInicio = picked : _fechaFin = picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Seleccionar';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == 'evento' && _fechaInicio == null) {
      _snack('Los eventos deben tener al menos fecha de inicio');
      return;
    }
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/noticias/${widget.espacioId}'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titulo'] = _tituloCtrl.text.trim();
      request.fields['descripcion'] = _descripcionCtrl.text.trim();
      request.fields['tipo'] = _tipo;
      if (_fechaInicio != null) request.fields['fechaInicio'] = _fechaInicio!.toIso8601String();
      if (_fechaFin != null) request.fields['fechaFin'] = _fechaFin!.toIso8601String();
      if (_imagenFile != null) {
        if (kIsWeb) {
          final bytes = await _imagenFile!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: _imagenFile!.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('imagen', _imagenFile!.path));
        }
      }
      final resp = await request.send();
      if (resp.statusCode == 201) {
        _snack('¡Publicación creada!');
        if (mounted) Navigator.pop(context, true);
      } else { _snack('Error al crear la publicación'); }
    } catch (e) { _snack('Error: $e'); }
    setState(() => _loading = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _primaryDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: _primaryDeep,
        title: Text('Nueva Publicación', style: GoogleFonts.sansita(fontWeight: FontWeight.w900, color: _primaryDeep, fontSize: 24)),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                _buildHeader(Icons.category_rounded, 'Tipo de publicación'),
                const SizedBox(height: 16),
                Row(children: [
                  _tipoChip('noticia', Icons.newspaper_rounded, 'Noticia'),
                  const SizedBox(width: 12),
                  _tipoChip('evento', Icons.event_rounded, 'Evento'),
                ]),
                const SizedBox(height: 32),

                _buildHeader(Icons.image_rounded, 'Imagen de portada'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180, width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.03), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: _primaryDeep.withValues(alpha: 0.08), width: 1.5),
                    ),
                    child: _imagenFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(22), child: kIsWeb ? Image.network(_imagenFile!.path, fit: BoxFit.cover, width: double.infinity) : Image.file(File(_imagenFile!.path), fit: BoxFit.cover, width: double.infinity))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.05), shape: BoxShape.circle),
                            child: Icon(Icons.add_photo_alternate_rounded, size: 32, color: _primaryDeep.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 12),
                          Text('Seleccionar imagen', style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
                const SizedBox(height: 32),

                _buildHeader(Icons.edit_note_rounded, 'Detalles'),
                const SizedBox(height: 20),
                _buildInput(controller: _tituloCtrl, label: 'Título de la publicación', hint: 'Ej: ¡Gran Final este Domingo!', icon: Icons.title_rounded),
                const SizedBox(height: 20),
                _buildInput(controller: _descripcionCtrl, label: 'Descripción', hint: 'Escribe los detalles aquí...', icon: Icons.description_rounded, maxLines: 5),

                if (_tipo == 'evento') ...[
                  const SizedBox(height: 32),
                  _buildHeader(Icons.calendar_month_rounded, 'Fechas del evento'),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _dateButton('Inicia', _fechaInicio, () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateButton('Termina (opc)', _fechaFin, () => _pickDate(false))),
                  ]),
                ],

                const SizedBox(height: 48),
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryDeep, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4, shadowColor: _primaryDeep.withValues(alpha: 0.3),
                    ),
                    onPressed: _loading ? null : _crear,
                    child: Text('Publicar Ahora', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_loading) Container(color: Colors.white.withValues(alpha: 0.6), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: _primaryDeep, size: 20),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep)),
    ]);
  }

  Widget _buildInput({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryDeep.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, maxLines: maxLines,
        style: GoogleFonts.sansita(fontSize: 16, color: _primaryDeep, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.3)),
          prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 0), child: Icon(icon, color: _primaryDeep.withValues(alpha: 0.4), size: 20)),
          filled: true, fillColor: _primaryDeep.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _primaryDeep.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: _primaryDeep.withValues(alpha: 0.2), width: 1.5)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
      ),
    ]);
  }

  Widget _tipoChip(String value, IconData icon, String label) {
    final isSelected = _tipo == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryDeep : _primaryDeep.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _primaryDeep : _primaryDeep.withValues(alpha: 0.1)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : _primaryDeep.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : _primaryDeep.withValues(alpha: 0.6))),
        ]),
      ),
    ));
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: date != null ? _primaryDeep.withValues(alpha: 0.2) : _primaryDeep.withValues(alpha: 0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: date != null ? _primaryDeep : _primaryDeep.withValues(alpha: 0.3)),
            const SizedBox(width: 8),
            Text(_formatDate(date), style: GoogleFonts.sansita(fontWeight: FontWeight.w800, color: date != null ? _primaryDeep : _primaryDeep.withValues(alpha: 0.3), fontSize: 14)),
          ]),
        ]),
      ),
    );
  }
}
