import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class EditarEspacioPage extends StatefulWidget {
  final Map<String, dynamic> espacio;
  const EditarEspacioPage({super.key, required this.espacio});

  @override
  State<EditarEspacioPage> createState() => _EditarEspacioPageState();
}

class _EditarEspacioPageState extends State<EditarEspacioPage> {
  final Color _primaryDeep = const Color(0xFF19382F);
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nombreCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _descripcionCtrl;
  File? _nuevaPortada;
  late String _espacioId;

  @override
  void initState() {
    super.initState();
    _espacioId = widget.espacio['_id'] ?? '';
    _nombreCtrl = TextEditingController(text: widget.espacio['nombre'] ?? '');
    _ubicacionCtrl =
        TextEditingController(text: widget.espacio['ubicacion'] ?? '');
    _descripcionCtrl =
        TextEditingController(text: widget.espacio['descripcion'] ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  // Guardar info básica
  Future<void> _guardarInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
          'PUT',
          Uri.parse(
              '${Config.baseUrl}/api/espacio/espacio-deportivo/$_espacioId'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre'] = _nombreCtrl.text;
      request.fields['ubicacion'] = _ubicacionCtrl.text;
      request.fields['descripcion'] = _descripcionCtrl.text;
      if (_nuevaPortada != null) {
        request.files.add(
            await http.MultipartFile.fromPath('imagen', _nuevaPortada!.path));
      }
      final resp = await request.send();
      _snack(resp.statusCode == 200
          ? '¡Información actualizada!'
          : 'Error al actualizar');
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _loading = false);
  }



  // Eliminar espacio completo
  Future<void> _eliminarEspacio() async {
    final confirm = await _showConfirm(
        '¿Estás seguro de eliminar este espacio? Esta acción no se puede deshacer. Se eliminarán todos sus servicios y noticias.');
    if (!confirm) return;
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final resp = await http.delete(
        Uri.parse(
            '${Config.baseUrl}/api/espacio/espacio-deportivo/$_espacioId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        _snack('Espacio eliminado');
        if (mounted)
          Navigator.of(context)
            ..pop()
            ..pop();
      } else {
        _snack('Error al eliminar el espacio');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<bool> _showConfirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirmar',
                style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
            content: Text(msg, style: GoogleFonts.sansita()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancelar', style: GoogleFonts.sansita())),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Confirmar',
                      style: GoogleFonts.sansita(
                          color: Colors.red, fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.sansita())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: _primaryDeep,
            elevation: 0,
            title: Text('Editar espacio',
                style: GoogleFonts.sansita(
                    fontWeight: FontWeight.w800, color: _primaryDeep)),
            actions: [
              IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade400),
                  onPressed: _loading ? null : _eliminarEspacio,
                  tooltip: 'Eliminar espacio'),
            ],
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── INFO BÁSICA ──
              const SizedBox(height: 10),
              Form(
                  key: _formKey,
                  child: Column(children: [
                    _buildField(_nombreCtrl, 'Nombre del espacio',
                        'Ej: Polideportivo Sur', Icons.business_rounded),
                    const SizedBox(height: 18),
                    _buildField(_ubicacionCtrl, 'Ubicación / Dirección',
                        'Ej: Av. Amazonas 123', Icons.location_on_rounded),
                    const SizedBox(height: 18),
                    _buildField(
                        _descripcionCtrl,
                        'Descripción del lugar',
                        'Cuéntale a los jugadores sobre tu espacio...',
                        Icons.description_rounded,
                        maxLines: 4),
                  ])),
              const SizedBox(height: 24),
              // Portada
              if (_nuevaPortada != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_nuevaPortada!,
                        height: 140, width: double.infinity, fit: BoxFit.cover))
              else if (widget.espacio['imagen'] != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(widget.espacio['imagen'],
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: () async {
                    final f =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (f != null) setState(() => _nuevaPortada = File(f.path));
                  },
                  icon:
                      Icon(Icons.image_rounded, color: _primaryDeep, size: 20),
                  label: Text('Cambiar portada',
                      style: GoogleFonts.sansita(
                          color: _primaryDeep, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: _primaryDeep.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: _loading ? null : _guardarInfo,
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text('Actualizar',
                      style: GoogleFonts.sansita(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor: _primaryDeep.withValues(alpha: 0.3),
                  ),
                )),
              ]),
              const SizedBox(height: 32),

            ]),
          )),
        ]),
        if (_loading)
          Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white))),
      ]),
    );
  }


  Widget _buildField(
      TextEditingController ctrl, String label, String hint, IconData icon,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: GoogleFonts.sansita(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryDeep.withValues(alpha: 0.6))),
        ),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.sansita(
              fontSize: 16, color: _primaryDeep, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon,
                color: _primaryDeep.withValues(alpha: 0.4), size: 20),
            filled: true,
            fillColor: _primaryDeep.withValues(alpha: 0.03),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: _primaryDeep.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                    color: _primaryDeep.withValues(alpha: 0.2), width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.red.withValues(alpha: 0.2))),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.red, width: 2)),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
        ),
      ],
    );
  }
}
