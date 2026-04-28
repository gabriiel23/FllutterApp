import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class CrearEspacioDeportivoPage extends StatefulWidget {
  const CrearEspacioDeportivoPage({super.key});

  @override
  _CrearEspacioDeportivoPageState createState() => _CrearEspacioDeportivoPageState();
}

class _CrearEspacioDeportivoPageState extends State<CrearEspacioDeportivoPage> {
  final Color _primaryDeep = const Color(0xFF19382F);
  int _step = 0;
  bool _loading = false;

  // Step 1: Info General
  final _infoKey = GlobalKey<FormState>();
  String _nombre = '', _ubicacion = '', _descripcion = '';
  XFile? _portadaFile;
  final List<XFile> _galeriaFiles = [];

  // Step 2: Servicios
  final List<Map<String, dynamic>> _servicios = [];

  // Step 3: Cuentas Bancarias
  final List<Map<String, dynamic>> _cuentasBancarias = [];

  final ImagePicker _picker = ImagePicker();

  // ── PORTADA & GALERÍA ───────────────────────────────────────────────────
  Future<void> _pickPortada() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) setState(() => _portadaFile = f);
  }

  Future<void> _addGaleriaImage() async {
    if (_galeriaFiles.length >= 10) {
      _snack('Máximo 10 imágenes en la galería');
      return;
    }
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _galeriaFiles.add(f));
  }

  void _removeGaleriaImage(int i) => setState(() => _galeriaFiles.removeAt(i));

  // ── SERVICIOS ─────────────────────────────────────────────────────────────
  void _addServicio(Map<String, dynamic> s) => setState(() => _servicios.add(s));
  void _removeServicio(int i) => setState(() => _servicios.removeAt(i));

  // ── CUENTAS BANCARIAS ─────────────────────────────────────────────────────
  void _addCuenta(Map<String, dynamic> c) => setState(() => _cuentasBancarias.add(c));
  void _removeCuenta(int i) => setState(() => _cuentasBancarias.removeAt(i));

  // ── SUBMIT ────────────────────────────────────────────────────────────────
  Future<void> _crear() async {
    setState(() => _loading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final userId = prefs.getString('userId') ?? '';

      // 1. Crear espacio con portada y galería
      var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/espacio/espacio-deportivo'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre'] = _nombre;
      request.fields['ubicacion'] = _ubicacion;
      request.fields['descripcion'] = _descripcion;
      request.fields['propietario'] = userId;
      if (_portadaFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes('imagen', await _portadaFile!.readAsBytes(), filename: _portadaFile!.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('imagen', _portadaFile!.path));
        }
      }
      for (final f in _galeriaFiles) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes('galeria', await f.readAsBytes(), filename: f.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('galeria', f.path));
        }
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 201) {
        _snack('Error al crear el espacio');
        setState(() => _loading = false);
        return;
      }

      final espacioData = jsonDecode(body);
      final espacioId = espacioData['_id'];
      await prefs.setString('espacio_id', espacioId);

      // 2. Crear cuentas bancarias
      for (final c in _cuentasBancarias) {
        await http.post(
          Uri.parse('${Config.baseUrl}/api/espacio/espacio-deportivo/$espacioId/cuentas-bancarias'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(c),
        );
      }

      // 3. Crear servicios
      for (final s in _servicios) {
        var sReq = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/$espacioId'));
        sReq.headers['Authorization'] = 'Bearer $token';
        sReq.fields['nombre'] = s['nombre'];
        sReq.fields['tipo'] = s['tipo'];
        
        // El frontend ahora manda los precios y configuraciones
        if (s['precioDia'] != null) sReq.fields['precioDia'] = s['precioDia'].toString();
        if (s['precioNoche'] != null) sReq.fields['precioNoche'] = s['precioNoche'].toString();
        if (s['horaInicioNoche'] != null) sReq.fields['horaInicioNoche'] = s['horaInicioNoche'];
        if (s['diasAbierto'] != null) sReq.fields['diasAbierto'] = jsonEncode(s['diasAbierto']);
        if (s['microservicios'] != null) sReq.fields['microservicios'] = jsonEncode(s['microservicios']);

        // Se envía un horario genérico solo como placeholder (la flexibilidad la dan los nuevos campos)
        sReq.fields['horarios'] = jsonEncode([{
          'inicio': '08:00',
          'fin': '22:00',
          'precio': s['precioDia'] ?? 0,
          'disponible': true
        }]);

        await sReq.send();
      }

      if (mounted) {
        _snack('¡Espacio creado con éxito!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _loading = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.sansita())));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _buildHeader(),
        _buildStepIndicator(),
        Expanded(child: _buildStepContent()),
        _buildBottomBar(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))
      ]),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Material(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 42, height: 42, child: Icon(Icons.arrow_back_rounded, size: 22, color: _primaryDeep)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.add_business_rounded, size: 24, color: _primaryDeep),
              ),
              const SizedBox(width: 12),
              Text('Nuevo espacio', style: GoogleFonts.sansita(fontSize: 30, fontWeight: FontWeight.w800, color: _primaryDeep, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 6),
            Text('Completa los pasos para registrar tu espacio', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5))),
          ]),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Información', 'Servicios', 'Cuentas', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final isCompleted = _step > i ~/ 2;
            return Expanded(child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              color: isCompleted ? _primaryDeep : _primaryDeep.withValues(alpha: 0.12),
            ));
          }
          final idx = i ~/ 2;
          final isActive = _step == idx;
          final isCompleted = _step > idx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 36 : 30, height: isActive ? 36 : 30,
            decoration: BoxDecoration(
              color: (isCompleted || isActive) ? _primaryDeep : _primaryDeep.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(child: isCompleted
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : Text('${idx + 1}', style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : _primaryDeep.withValues(alpha: 0.4)))),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey(_step),
        padding: const EdgeInsets.all(24),
        child: _step == 0 ? _buildStepInfo() : _step == 1 ? _buildStepServicios() : _step == 2 ? _buildStepCuentas() : _buildStepConfirmar(),
      ),
    );
  }

  // ── STEP 1: INFO GENERAL ──────────────────────────────────────────────────
  Widget _buildStepInfo() {
    return Form(
      key: _infoKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Información general'),
        const SizedBox(height: 20),
        _field('Nombre del espacio', 'Ej: Polideportivo Sur', (v) => _nombre = v!, initialValue: _nombre),
        const SizedBox(height: 16),
        _field('Dirección / Ubicación', 'Ej: Av. Amazonas 123', (v) => _ubicacion = v!, initialValue: _ubicacion),
        const SizedBox(height: 16),
        _field('Descripción', 'Describe tu espacio deportivo...', (v) => _descripcion = v!, maxLines: 4, initialValue: _descripcion),
        const SizedBox(height: 24),
        
        _sectionTitle('Foto de portada'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickPortada,
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryDeep.withValues(alpha: 0.15), style: BorderStyle.solid),
            ),
            child: _portadaFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16), 
                  child: kIsWeb 
                    ? Image.network(_portadaFile!.path, fit: BoxFit.cover, width: double.infinity)
                    : Image.file(File(_portadaFile!.path), fit: BoxFit.cover, width: double.infinity)
                )
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 48, color: _primaryDeep.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('Toca para subir foto de portada', style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4), fontSize: 14)),
                ]),
          ),
        ),
        const SizedBox(height: 24),

        _sectionTitle('Galería de fotos'),
        const SizedBox(height: 4),
        Text('Agrega hasta 10 fotos (${_galeriaFiles.length}/10)', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: _galeriaFiles.length + (_galeriaFiles.length < 10 ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _galeriaFiles.length) {
              return GestureDetector(
                onTap: _addGaleriaImage,
                child: Container(
                  decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryDeep.withValues(alpha: 0.15))),
                  child: Icon(Icons.add_rounded, size: 32, color: _primaryDeep.withValues(alpha: 0.4)),
                ),
              );
            }
            return Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12), 
                child: kIsWeb
                  ? Image.network(_galeriaFiles[i].path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                  : Image.file(File(_galeriaFiles[i].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              ),
              Positioned(top: 4, right: 4, child: GestureDetector(
                onTap: () => _removeGaleriaImage(i),
                child: Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              )),
            ]);
          },
        ),
      ]),
    );
  }

  // ── STEP 2: SERVICIOS ─────────────────────────────────────────────────────
  Widget _buildStepServicios() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Servicios disponibles'),
      const SizedBox(height: 4),
      Text('Configura los servicios (canchas, piscinas) y sus precios', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
      const SizedBox(height: 20),
      if (_servicios.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text('Aún no has agregado servicios.\nUsa el botón de abajo para agregar.', textAlign: TextAlign.center, style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4), fontSize: 14))),
        ),
      ..._servicios.asMap().entries.map((e) => _buildServicioCard(e.key, e.value)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showAddServicioSheet(),
          icon: Icon(Icons.add_rounded, color: _primaryDeep),
          label: Text('Agregar servicio', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: _primaryDeep)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: _primaryDeep.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildServicioCard(int idx, Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(s['tipo'] == 'Piscina' ? Icons.pool_rounded : Icons.sports_soccer_rounded, color: _primaryDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['nombre'], style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: _primaryDeep, fontSize: 15)),
          Text('${s['tipo']} · Día: \$${s['precioDia']} · Noche: \$${s['precioNoche']}', style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
          if ((s['microservicios'] as List).isNotEmpty)
            Text('Incluye: ${(s['microservicios'] as List).join(', ')}', style: GoogleFonts.sansita(fontSize: 11, color: _primaryDeep.withValues(alpha: 0.4))),
        ])),
        IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20), onPressed: () => _removeServicio(idx)),
      ]),
    );
  }

  void _showAddServicioSheet() {
    final formKey = GlobalKey<FormState>();
    String nombre = '', tipo = 'Cancha', horaInicioNoche = '18:00', microstr = '';
    double precioDia = 10, precioNoche = 15;
    List<int> diasAbierto = [1,2,3,4,5,6,7]; // Todos los días por defecto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agregar servicio', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryDeep)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre del servicio', hintText: 'Ej: Cancha Sintética 1', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => nombre = v!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Cancha', 'Piscina', 'Ecuavoley', 'Otro'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => tipo = v!,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(
                  initialValue: '10',
                  decoration: InputDecoration(labelText: 'Precio Día (\$)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => precioDia = double.tryParse(v!) ?? 10,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  initialValue: '15',
                  decoration: InputDecoration(labelText: 'Precio Noche (\$)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onSaved: (v) => precioNoche = double.tryParse(v!) ?? 15,
                )),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '18:00',
                decoration: InputDecoration(labelText: 'Inicio de tarifa nocturna (HH:MM)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => horaInicioNoche = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Microservicios (separados por coma)', hintText: 'Ej: Sauna, Turco, Balón incluido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onSaved: (v) => microstr = v!,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    List<String> micros = microstr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    _addServicio({
                      'nombre': nombre, 'tipo': tipo, 
                      'precioDia': precioDia, 'precioNoche': precioNoche, 
                      'horaInicioNoche': horaInicioNoche, 
                      'microservicios': micros, 'diasAbierto': diasAbierto
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text('Agregar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── STEP 3: CUENTAS BANCARIAS ─────────────────────────────────────────────
  Widget _buildStepCuentas() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Métodos de pago'),
      const SizedBox(height: 4),
      Text('Agrega las cuentas bancarias donde recibirás los pagos', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
      const SizedBox(height: 20),
      if (_cuentasBancarias.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text('Aún no has agregado cuentas bancarias.\nUsa el botón de abajo para agregar.', textAlign: TextAlign.center, style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4), fontSize: 14))),
        ),
      ..._cuentasBancarias.asMap().entries.map((e) => _buildCuentaCard(e.key, e.value)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showAddCuentaSheet(),
          icon: Icon(Icons.add_rounded, color: _primaryDeep),
          label: Text('Agregar cuenta', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: _primaryDeep)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: _primaryDeep.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCuentaCard(int idx, Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.account_balance_rounded, color: _primaryDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['banco'], style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: _primaryDeep, fontSize: 15)),
          Text('Titular: ${c['titular']}', style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.6))),
          Text('Cta: ${c['numeroCuenta']} · CI: ${c['cedula']}', style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep.withValues(alpha: 0.4))),
        ])),
        IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20), onPressed: () => _removeCuenta(idx)),
      ]),
    );
  }

  void _showAddCuentaSheet() {
    final formKey = GlobalKey<FormState>();
    String banco = '', titular = '', numeroCuenta = '', cedula = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agregar cuenta', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryDeep)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Banco', hintText: 'Ej: Banco Pichincha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => banco = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre del titular', hintText: 'Ej: Juan Pérez', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => titular = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Número de cuenta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => numeroCuenta = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cédula / RUC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => cedula = v!,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryDeep, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    _addCuenta({'banco': banco, 'titular': titular, 'numeroCuenta': numeroCuenta, 'cedula': cedula});
                    Navigator.pop(ctx);
                  },
                  child: Text('Agregar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── STEP 4: CONFIRMACIÓN ──────────────────────────────────────────────────
  Widget _buildStepConfirmar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Confirmar y crear'),
      const SizedBox(height: 4),
      Text('Revisa la información antes de crear tu espacio', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
      const SizedBox(height: 24),
      _confirmRow(Icons.business_rounded, 'Nombre', _nombre),
      _confirmRow(Icons.location_on_rounded, 'Ubicación', _ubicacion),
      _confirmRow(Icons.description_rounded, 'Descripción', _descripcion.length > 60 ? '${_descripcion.substring(0, 60)}...' : _descripcion),
      _confirmRow(Icons.image_rounded, 'Portada', _portadaFile != null ? 'Imagen seleccionada ✓' : 'Sin imagen'),
      _confirmRow(Icons.photo_library_rounded, 'Galería', '${_galeriaFiles.length} foto(s)'),
      
      const SizedBox(height: 16),
      Text('Servicios', style: GoogleFonts.sansita(fontWeight: FontWeight.w800, color: _primaryDeep, fontSize: 16)),
      const SizedBox(height: 8),
      if (_servicios.isEmpty) Text('Sin servicios', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5)))
      else ..._servicios.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(Icons.circle, size: 6, color: _primaryDeep.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Text('${s['nombre']} (\$${s['precioDia']} / \$${s['precioNoche']})', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep))),
        ]),
      )),
      
      const SizedBox(height: 16),
      Text('Cuentas Bancarias', style: GoogleFonts.sansita(fontWeight: FontWeight.w800, color: _primaryDeep, fontSize: 16)),
      const SizedBox(height: 8),
      if (_cuentasBancarias.isEmpty) Text('Sin cuentas', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5)))
      else ..._cuentasBancarias.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(Icons.circle, size: 6, color: _primaryDeep.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Text('${c['banco']} - ${c['numeroCuenta']}', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep))),
        ]),
      )),
    ]);
  }

  Widget _confirmRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: _primaryDeep.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Text('$label: ', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5))),
        Expanded(child: Text(value, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryDeep))),
      ]),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    bool canContinue = true;
    if (_step == 1 && _servicios.isEmpty) canContinue = false;
    // (Opcional) Si quieres obligar a poner cuentas bancarias: if (_step == 2 && _cuentasBancarias.isEmpty) canContinue = false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6))]),
      child: SafeArea(top: false, child: Row(children: [
        if (_step > 0) ...[
          Material(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => setState(() => _step--),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 52, height: 52, child: Icon(Icons.arrow_back_rounded, color: _primaryDeep, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_loading || !canContinue) ? null : () {
              if (_step == 0) {
                if (!_infoKey.currentState!.validate()) return;
                _infoKey.currentState!.save();
                setState(() => _step++);
              } else if (_step < 3) {
                setState(() => _step++);
              } else {
                _crear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryDeep,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryDeep.withValues(alpha: 0.2),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(_step == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 20),
            label: Text(
              _loading ? 'Creando...' : _step == 3 ? 'Crear espacio' : 'Continuar',
              style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        )),
      ])),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDeep));
  }

  Widget _field(String label, String hint, Function(String?) onSaved, {int maxLines = 1, String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.6)),
        hintStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryDeep.withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryDeep, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        filled: true,
        fillColor: _primaryDeep.withValues(alpha: 0.03),
      ),
      style: GoogleFonts.sansita(color: _primaryDeep),
      validator: (v) => v == null || v.trim().isEmpty ? 'Este campo es requerido' : null,
      onSaved: onSaved,
    );
  }
}
