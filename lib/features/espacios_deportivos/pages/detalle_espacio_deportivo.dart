import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';
import 'crear_servicio_page.dart';
import 'editar_espacio_page.dart';
import 'crear_noticia_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutterapp/features/reserves/presentation/pages/reserva_flow_page.dart';

class DetalleEspacioDeportivoPage extends StatefulWidget {
  final Map<String, dynamic> espacio;
  const DetalleEspacioDeportivoPage({super.key, required this.espacio});

  @override
  _DetalleEspacioDeportivoPageState createState() =>
      _DetalleEspacioDeportivoPageState();
}

class _DetalleEspacioDeportivoPageState
    extends State<DetalleEspacioDeportivoPage> {
  late String espacioId;
  List<dynamic> servicios = [];
  List<dynamic> noticias = [];
  bool isLoading = true;
  String baseUrl = Config.baseUrl;
  String? userRol;
  late Map<String, dynamic> _espacio;

  late PageController _newsPageController;
  int _newsCurrentPage = 0;
  Timer? _newsTimer;

  final Color _primaryDeep = const Color(0xFF19382F);
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _newsPageController = PageController();
    _espacio = Map<String, dynamic>.from(widget.espacio);
    _loadUserData();
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    _newsTimer?.cancel();
    super.dispose();
  }

  void _startAutoCarousel() {
    _newsTimer?.cancel();
    if (noticias.isEmpty) return;
    _newsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || noticias.isEmpty) return;
      final next = (_newsCurrentPage + 1) % noticias.length;
      _newsPageController.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      espacioId = prefs.getString('espacio_id') ?? _espacio['_id'] ?? '';
      userRol = prefs.getString('userRol');
    });
    await Future.wait([_fetchEspacio(), _fetchServicios(), _fetchNoticias()]);
  }

  Future<void> _fetchEspacio() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/api/espacio/espacio-deportivo/$espacioId'));
      if (response.statusCode == 200) {
        setState(() => _espacio = json.decode(response.body));
      }
    } catch (_) {}
  }

  Future<void> _fetchServicios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/$espacioId'));
      if (response.statusCode == 200) {
        setState(() {
          servicios = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchNoticias() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/noticias/$espacioId'));
      if (response.statusCode == 200) {
        setState(() {
          noticias = json.decode(response.body);
          _newsCurrentPage = 0;
        });
        _startAutoCarousel();
      }
    } catch (_) {}
  }

  Future<void> _agregarImagen() async {
    final galeria = List<String>.from(_espacio['galeria'] ?? []);
    if (galeria.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Máximo 10 imágenes', style: GoogleFonts.sansita())));
      return;
    }
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f == null) return;
    setState(() => _isUploadingImage = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/espacio/espacio-deportivo/$espacioId/galeria'));
      request.headers['Authorization'] = 'Bearer $token';
      
      if (kIsWeb) {
        final bytes = await f.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: f.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('imagen', f.path));
      }
      
      final streamed = await request.send();
      if (streamed.statusCode == 200) {
        final body = await streamed.stream.bytesToString();
        final data = jsonDecode(body);
        setState(() => _espacio['galeria'] = List<String>.from(data['galeria'] ?? []));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen agregada', style: GoogleFonts.sansita())));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar imagen', style: GoogleFonts.sansita())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.sansita())));
    }
    setState(() => _isUploadingImage = false);
  }

  Future<void> _eliminarImagen(String url) async {
    final confirm = await _showConfirmDialog('Eliminar imagen', '¿Eliminar esta imagen de la galería?');
    if (!confirm) return;
    setState(() => _isUploadingImage = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.delete(
        Uri.parse('${Config.baseUrl}/api/espacio/espacio-deportivo/$espacioId/galeria'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'imagenUrl': url}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _espacio['galeria'] = List<String>.from(data['galeria'] ?? []));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen eliminada', style: GoogleFonts.sansita())));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar', style: GoogleFonts.sansita())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.sansita())));
    }
    setState(() => _isUploadingImage = false);
  }

  Future<void> _eliminarNoticia(String noticiaId) async {
    final confirm = await _showConfirmDialog('Eliminar publicación', '¿Estás seguro de que quieres eliminar esta publicación?');
    if (!confirm) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.delete(
          Uri.parse('$baseUrl/api/noticias/$noticiaId'),
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        setState(() => noticias.removeWhere((n) => n['_id'] == noticiaId));
        _showSnack('Publicación eliminada');
      }
    } catch (_) {}
  }

  Future<void> _eliminarServicio(String servicioId) async {
    final confirm = await _showConfirmDialog('Eliminar servicio', '¿Estás seguro de que quieres eliminar este servicio?');
    if (!confirm) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.delete(Uri.parse('$baseUrl/api/$servicioId'),
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        setState(() => servicios.removeWhere((s) => s['_id'] == servicioId));
        _showSnack('Servicio eliminado');
      }
    } catch (_) {}
  }

  Future<void> _eliminarCuentaBancaria(String cuentaId) async {
    final confirm = await _showConfirmDialog('Eliminar cuenta', '¿Estás seguro de que quieres eliminar esta cuenta bancaria?');
    if (!confirm) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.delete(
          Uri.parse('$baseUrl/api/espacio/espacio-deportivo/$espacioId/cuentas-bancarias/$cuentaId'),
          headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        await _fetchEspacio();
        _showSnack('Cuenta eliminada');
      }
    } catch (_) {}
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title,
                style: GoogleFonts.sansita(
                    fontWeight: FontWeight.bold, color: _primaryDeep)),
            content: Text(content, style: GoogleFonts.sansita(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar',
                    style: GoogleFonts.sansita(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text('Eliminar',
                    style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita()),
      backgroundColor: _primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  bool get _isAdmin =>
      userRol == 'administrador' || userRol == 'superadmin';

  // ── BOTTOM SHEET: CUENTA ─────────────────────────────────────────────────
  void _showAddCuentaSheet({Map<String, dynamic>? cuenta}) {
    final formKey = GlobalKey<FormState>();
    final bancoCtrl = TextEditingController(text: cuenta?['banco'] ?? '');
    final titularCtrl = TextEditingController(text: cuenta?['titular'] ?? '');
    final numeroCtrl = TextEditingController(text: cuenta?['numeroCuenta'] ?? '');
    final cedulaCtrl = TextEditingController(text: cuenta?['cedula'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                        color: _primaryDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                        cuenta == null ? Icons.add_card_rounded : Icons.edit_note_rounded,
                        color: _primaryDeep, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(cuenta == null ? 'Nueva cuenta bancaria' : 'Editar cuenta',
                      style: GoogleFonts.sansita(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: _primaryDeep, letterSpacing: -0.3)),
                ]),
                const SizedBox(height: 6),
                Text('Esta cuenta será mostrada a los usuarios para realizar pagos.',
                    style: GoogleFonts.sansita(
                        fontSize: 13, color: _primaryDeep.withValues(alpha: 0.45))),
                const SizedBox(height: 24),
                _buildCustomField(controller: bancoCtrl, label: 'Entidad Bancaria',
                    hint: 'Ej: Banco Pichincha', icon: Icons.account_balance_rounded),
                const SizedBox(height: 14),
                _buildCustomField(controller: titularCtrl, label: 'Nombre del Titular',
                    hint: 'Nombre completo', icon: Icons.person_rounded),
                const SizedBox(height: 14),
                _buildCustomField(controller: numeroCtrl, label: 'Número de Cuenta',
                    hint: '0000000000', icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                _buildCustomField(controller: cedulaCtrl, label: 'Cédula / RUC',
                    hint: 'Documento de identidad', icon: Icons.badge_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('userToken') ?? '';
                        http.Response resp;
                        if (cuenta == null) {
                          resp = await http.post(
                            Uri.parse('$baseUrl/api/espacio/espacio-deportivo/$espacioId/cuentas-bancarias'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: jsonEncode({'banco': bancoCtrl.text.trim(), 'titular': titularCtrl.text.trim(), 'numeroCuenta': numeroCtrl.text.trim(), 'cedula': cedulaCtrl.text.trim()}),
                          );
                        } else {
                          resp = await http.put(
                            Uri.parse('$baseUrl/api/espacio/espacio-deportivo/$espacioId/cuentas-bancarias/${cuenta['_id']}'),
                            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                            body: jsonEncode({'banco': bancoCtrl.text.trim(), 'titular': titularCtrl.text.trim(), 'numeroCuenta': numeroCtrl.text.trim(), 'cedula': cedulaCtrl.text.trim()}),
                          );
                        }
                        if (resp.statusCode == 201 || resp.statusCode == 200) {
                          await _fetchEspacio();
                          if (mounted) {
                            Navigator.pop(ctx);
                            _showSnack(cuenta == null ? '¡Cuenta registrada!' : '¡Cuenta actualizada!');
                          }
                        }
                      } catch (_) {}
                    },
                    child: Text(
                        cuenta == null ? 'Registrar cuenta' : 'Guardar cambios',
                        style: GoogleFonts.sansita(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showViewCuentaSheet(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: _primaryDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.account_balance_wallet_rounded, color: _primaryDeep, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Detalles de la cuenta',
                style: GoogleFonts.sansita(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDeep)),
          ]),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.account_balance_rounded, 'Banco', c['banco'] ?? 'No disponible'),
          _buildDivider(),
          _buildInfoRow(Icons.person_rounded, 'Titular', c['titular'] ?? 'No disponible'),
          _buildDivider(),
          _buildInfoRow(Icons.numbers_rounded, 'N° de Cuenta', c['numeroCuenta'] ?? 'No disponible'),
          _buildDivider(),
          _buildInfoRow(Icons.badge_rounded, 'Cédula / RUC', c['cedula'] ?? 'No disponible'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primaryDeep.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: _primaryDeep),
              child: Text('Cerrar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showViewServicioSheet(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.sports_soccer_rounded, color: _primaryDeep, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['nombre'] ?? 'Servicio',
                    style: GoogleFonts.sansita(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _primaryDeep)),
                Text(s['tipo'] ?? 'Cancha',
                    style: GoogleFonts.sansita(
                        fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5))),
              ])),
            ]),
            const SizedBox(height: 24),
            Text('Tarifas', style: GoogleFonts.sansita(
                fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildTarifaCard(Icons.wb_sunny_rounded, 'Día', s['precioDia'], Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildTarifaCard(Icons.nights_stay_rounded, 'Noche', s['precioNoche'], Colors.indigo)),
            ]),
            if (s['horaInicioNoche'] != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 13, color: _primaryDeep.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('Nocturna desde las ${s['horaInicioNoche']}',
                    style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep.withValues(alpha: 0.5))),
              ]),
            ],
            const SizedBox(height: 24),
            Text('Días de apertura', style: GoogleFonts.sansita(
                fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _buildDiasChips(s['diasAbierto'])),
            if (s['microservicios'] != null && (s['microservicios'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Microservicios incluidos', style: GoogleFonts.sansita(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: (s['microservicios'] as List).map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primaryDeep.withValues(alpha: 0.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline_rounded, size: 13, color: _primaryDeep.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(m.toString(), style: GoogleFonts.sansita(
                        color: _primaryDeep, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                )).toList(),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryDeep.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: _primaryDeep),
                child: Text('Cerrar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showViewNoticiaSheet(Map<String, dynamic> n) {
    final isEvento = n['tipo'] == 'evento';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (n['imagen'] != null)
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Image.network(n['imagen'], height: 220,
                      width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Material(
                    color: Colors.white, shape: const CircleBorder(), elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(ctx),
                      child: const Padding(padding: EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded, size: 18)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14, left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _primaryDeep, borderRadius: BorderRadius.circular(8)),
                    child: Text(isEvento ? 'EVENTO' : 'NOTICIA',
                        style: GoogleFonts.sansita(
                            color: Colors.white, fontWeight: FontWeight.w800,
                            fontSize: 11, letterSpacing: 0.8)),
                  ),
                ),
              ])
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _sheetHandle(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['titulo'] ?? '',
                    style: GoogleFonts.sansita(
                        fontSize: 24, fontWeight: FontWeight.w900,
                        color: _primaryDeep, height: 1.2)),
                if (isEvento && n['fechaInicio'] != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _primaryDeep.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Icon(Icons.calendar_month_rounded, color: _primaryDeep, size: 18),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Fecha del evento',
                            style: GoogleFonts.sansita(fontSize: 11,
                                color: _primaryDeep.withValues(alpha: 0.5))),
                        Text(_formatDate(n['fechaInicio'], n['fechaFin']),
                            style: GoogleFonts.sansita(fontSize: 15,
                                color: _primaryDeep, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                  ),
                ],
                const SizedBox(height: 18),
                Text(n['descripcion'] ?? '',
                    style: GoogleFonts.sansita(
                        fontSize: 15, color: _primaryDeep.withValues(alpha: 0.65),
                        height: 1.6)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Entendido',
                        style: GoogleFonts.sansita(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── BUILD PRINCIPAL ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String imageUrl = _espacio['imagen'] != null &&
            _espacio['imagen'].toString().startsWith('http')
        ? _espacio['imagen']
        : 'https://img.freepik.com/foto-gratis/vista-cancha-futbol-iluminacion_23-2150888562.jpg';
    final List<String> galeria = List<String>.from(_espacio['galeria'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        CustomScrollView(slivers: [

          // ── SLIVER APP BAR ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: _primaryDeep,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: null,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(fit: StackFit.expand, children: [
                Image.network(imageUrl, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.60)
                      ],
                    ),
                  ),
                ),
                // Botón volver sobre la imagen
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: Material(
                    color: Colors.white, shape: const CircleBorder(), elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded, color: _primaryDeep, size: 22),
                      ),
                    ),
                  ),
                ),
                // Botón editar (solo admin)
                if (_isAdmin)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 16,
                    child: Material(
                      color: Colors.white, shape: const CircleBorder(), elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          final result = await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => EditarEspacioPage(espacio: _espacio)));
                          if (result == true && mounted) Navigator.pop(context, true);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.edit_rounded, color: _primaryDeep, size: 20),
                        ),
                      ),
                    ),
                  ),
                // Badge disponible
                Positioned(
                  bottom: 16, left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Disponible',
                          style: GoogleFonts.sansita(
                              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── CONTENIDO ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Nombre + Rating
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(_espacio['nombre'] ?? 'Espacio Deportivo',
                        style: GoogleFonts.sansita(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: _primaryDeep, letterSpacing: -0.5)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('4.8', style: GoogleFonts.sansita(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 16,
                      color: _primaryDeep.withValues(alpha: 0.45)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(_espacio['ubicacion'] ?? 'Sin ubicación',
                      style: GoogleFonts.sansita(
                          fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45)))),
                ]),

                if (servicios.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: servicios.take(4).map((s) =>
                        _buildChip(Icons.sports_soccer_rounded,
                            s['nombre'] ?? s['tipo'] ?? 'Servicio')).toList(),
                  ),
                ],
                const SizedBox(height: 28),

                // ── Descripción ──
                _buildSectionTitle(Icons.info_outline_rounded, 'Descripción'),
                const SizedBox(height: 10),
                Text(_espacio['descripcion'] ?? 'Sin descripción.',
                    style: GoogleFonts.sansita(
                        fontSize: 15, color: _primaryDeep.withValues(alpha: 0.6),
                        height: 1.5)),
                const SizedBox(height: 28),

                // ── Galería ──
                if (_isAdmin || galeria.isNotEmpty) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _buildSectionTitle(Icons.photo_library_rounded, 'Galería (${galeria.length}/10)'),
                    if (_isAdmin)
                      TextButton.icon(
                        onPressed: _isUploadingImage ? null : _agregarImagen,
                        icon: _isUploadingImage 
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryDeep))
                            : Icon(Icons.add_rounded, size: 16, color: _primaryDeep),
                        label: Text('Agregar', style: GoogleFonts.sansita(color: _primaryDeep, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (galeria.isEmpty && _isAdmin)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text('No hay imágenes en la galería', style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.35), fontSize: 14))),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: galeria.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(galeria[i], width: 120, height: 120, fit: BoxFit.cover),
                            ),
                            if (_isAdmin)
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => _eliminarImagen(galeria[i]),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                ],

                // ── Propietario ──
                _buildSectionTitle(Icons.person_outline_rounded, 'Propietario'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryDeep.withValues(alpha: 0.08))),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _primaryDeep.withValues(alpha: 0.12),
                      child: Text(
                          (_espacio['propietario']?['nombre'] ?? 'P')[0].toUpperCase(),
                          style: GoogleFonts.sansita(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: _primaryDeep)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_espacio['propietario']?['nombre'] ?? 'No disponible',
                          style: GoogleFonts.sansita(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: _primaryDeep)),
                      const SizedBox(height: 2),
                      Text(_espacio['propietario']?['email'] ?? '',
                          style: GoogleFonts.sansita(
                              fontSize: 13, color: _primaryDeep.withValues(alpha: 0.45))),
                    ])),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Servicios ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildSectionTitle(Icons.sports_rounded, 'Servicios disponibles'),
                  if (_isAdmin)
                    _buildHeaderAction(Icons.add_rounded, 'Nuevo', () =>
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CrearServicioPage()))
                            .then((_) => _fetchServicios())),
                ]),
                const SizedBox(height: 6),
                if (_isAdmin)
                  Text('Toca el ojo para ver detalles, edita o elimina un servicio.',
                      style: GoogleFonts.sansita(
                          fontSize: 12, color: _primaryDeep.withValues(alpha: 0.4))),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (servicios.isEmpty)
                  _buildEmptyState(Icons.sports_soccer_rounded,
                      'Sin servicios aún', 'Agrega el primer servicio con el botón +')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicios.length,
                    itemBuilder: (_, i) {
                      final s = servicios[i];
                      final horarios = (s['horarios'] as List?) ?? [];
                      final horarioStr = horarios.isNotEmpty
                          ? '${horarios.first['inicio']} – ${horarios.last['fin']}'
                          : 'Horario no definido';
                      return _buildServicioCard(s, horarioStr);
                    },
                  ),
                const SizedBox(height: 28),

                // ── Cuentas bancarias (solo admin) ──
                if (_isAdmin) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _buildSectionTitle(Icons.account_balance_rounded, 'Cuentas bancarias'),
                    _buildHeaderAction(Icons.add_rounded, 'Agregar', _showAddCuentaSheet),
                  ]),
                  const SizedBox(height: 6),
                  Text('Estas cuentas se muestran a los usuarios para realizar pagos.',
                      style: GoogleFonts.sansita(
                          fontSize: 12, color: _primaryDeep.withValues(alpha: 0.4))),
                  const SizedBox(height: 12),
                  if ((_espacio['cuentasBancarias'] as List?)?.isEmpty ?? true)
                    _buildEmptyState(Icons.account_balance_rounded,
                        'Sin cuentas bancarias', 'Agrega una cuenta para recibir pagos')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_espacio['cuentasBancarias'] as List).length,
                      itemBuilder: (_, i) {
                        final c = _espacio['cuentasBancarias'][i];
                        return _buildCuentaCard(c);
                      },
                    ),
                  const SizedBox(height: 28),
                ],

                // ── Noticias ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildSectionTitle(Icons.campaign_rounded, 'Noticias y eventos'),
                  if (_isAdmin)
                    _buildHeaderAction(Icons.add_rounded, 'Crear', () =>
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CrearNoticiaPage(espacioId: espacioId)))
                            .then((r) { if (r == true) _fetchNoticias(); })),
                ]),
                const SizedBox(height: 6),
                if (_isAdmin)
                  Text('Mantén informados a tus usuarios con avisos y eventos.',
                      style: GoogleFonts.sansita(
                          fontSize: 12, color: _primaryDeep.withValues(alpha: 0.4))),
                const SizedBox(height: 12),
                if (noticias.isEmpty)
                  _buildEmptyState(Icons.campaign_rounded,
                      'Sin noticias aún', 'Crea un aviso o evento para tus usuarios')
                else
                  _newsCarousel(),
              ]),
            ),
          ),
        ]),

        // ── BOTÓN RESERVAR (solo usuarios) ──────────────────────────────
        if (!_isAdmin)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    blurRadius: 20, offset: const Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSeleccionServicioSheet(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: Text('Reservar ahora',
                        style: GoogleFonts.sansita(
                            fontSize: 17, fontWeight: FontWeight.bold,
                            letterSpacing: 0.3)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
  // ── SELECCIÓN DE SERVICIO PARA RESERVAR ──────────────────────────────────
  void _showSeleccionServicioSheet() {
    if (servicios.isEmpty) {
      _showSnack('No hay servicios disponibles para reservar');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Selecciona un servicio', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryDeep)),
            Text('¿Qué quieres reservar?', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
            const SizedBox(height: 20),
            ...servicios.map((s) {
              final horarios = (s['horarios'] as List?) ?? [];
              final horarioStr = horarios.isNotEmpty ? '${horarios.first['inicio']} – ${horarios.last['fin']}' : 'Sin horario';
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ReservaFlowPage(servicio: Map<String, dynamic>.from(s), espacio: Map<String, dynamic>.from(_espacio)),
                  )).then((r) { if (r == true && mounted) { /* could refresh */ } });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _primaryDeep.withValues(alpha: 0.12)),
                    boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.sports_rounded, color: _primaryDeep, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['nombre'] ?? 'Servicio', style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryDeep)),
                      Text(horarioStr, style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.45))),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: _primaryDeep.withValues(alpha: 0.3)),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }

  // ── CARDS REUTILIZABLES ───────────────────────────────────────────────────
  Widget _buildServicioCard(Map<String, dynamic> s, String horarioStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.sports_soccer_rounded, color: _primaryDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['nombre'] ?? 'Servicio',
              style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDeep)),
          Text(horarioStr,
              style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep.withValues(alpha: 0.45))),
        ])),
        // Acciones
        IconButton(
          icon: Icon(Icons.remove_red_eye_rounded, color: Colors.indigo.shade300, size: 20),
          onPressed: () => _showViewServicioSheet(s),
          tooltip: 'Ver detalles',
        ),
        if (_isAdmin) ...[
          IconButton(
            icon: Icon(Icons.edit_rounded, color: Colors.blue.shade300, size: 18),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CrearServicioPage(servicio: s)))
                .then((_) => _fetchServicios()),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 18),
            onPressed: () => _eliminarServicio(s['_id']),
            tooltip: 'Eliminar',
          ),
        ],
      ]),
    );
  }

  Widget _buildCuentaCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.account_balance_rounded, color: _primaryDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['banco'] ?? 'Banco',
              style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDeep)),
          Text('${c['titular']} · ${c['numeroCuenta']}',
              style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep.withValues(alpha: 0.45))),
        ])),
        IconButton(
          icon: Icon(Icons.remove_red_eye_rounded, color: Colors.indigo.shade300, size: 20),
          onPressed: () => _showViewCuentaSheet(c),
        ),
        IconButton(
          icon: Icon(Icons.edit_rounded, color: Colors.blue.shade300, size: 18),
          onPressed: () => _showAddCuentaSheet(cuenta: c),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 18),
          onPressed: () => _eliminarCuentaBancaria(c['_id']),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Icon(icon, size: 36, color: _primaryDeep.withValues(alpha: 0.18)),
        const SizedBox(height: 10),
        Text(title, style: GoogleFonts.sansita(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: _primaryDeep.withValues(alpha: 0.3))),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.sansita(
            fontSize: 12, color: _primaryDeep.withValues(alpha: 0.25)),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: _primaryDeep.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: _primaryDeep),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.sansita(
                fontSize: 13, fontWeight: FontWeight.bold, color: _primaryDeep)),
          ]),
        ),
      ),
    );
  }

  // ── CAROUSEL ──────────────────────────────────────────────────────────────
  Widget _newsCarousel() {
    return Column(children: [
      SizedBox(
        height: 230,
        child: PageView.builder(
          controller: _newsPageController,
          itemCount: noticias.length,
          onPageChanged: (idx) => setState(() => _newsCurrentPage = idx),
          itemBuilder: (ctx, i) => _buildNoticiaCard(noticias[i]),
        ),
      ),
      const SizedBox(height: 12),
      _dotIndicator(noticias.length, _newsCurrentPage),
    ]);
  }

  Widget _dotIndicator(int length, int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: i == current ? 18 : 6, height: 6,
        decoration: BoxDecoration(
            color: i == current ? _primaryDeep : _primaryDeep.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10)),
      )),
    );
  }

  Widget _buildNoticiaCard(Map<String, dynamic> n) {
    final isTipoEvento = n['tipo'] == 'evento';
    return GestureDetector(
      onTap: () => _showViewNoticiaSheet(n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: _primaryDeep,
          borderRadius: BorderRadius.circular(20),
          image: n['imagen'] != null
              ? DecorationImage(image: NetworkImage(n['imagen']), fit: BoxFit.cover)
              : null,
          boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.12),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
              stops: const [0.45, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: _primaryDeep, borderRadius: BorderRadius.circular(7)),
                  child: Text(isTipoEvento ? 'EVENTO' : 'AVISO',
                      style: GoogleFonts.sansita(fontSize: 10, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 0.8)),
                ),
                const Spacer(),
                if (_isAdmin)
                  GestureDetector(
                    onTap: () => _eliminarNoticia(n['_id']),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.white70),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(n['titulo'] ?? '', style: GoogleFonts.sansita(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(n['descripcion'] ?? '', style: GoogleFonts.sansita(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 17, color: _primaryDeep),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.sansita(
          fontSize: 17, fontWeight: FontWeight.w800,
          color: _primaryDeep, letterSpacing: -0.3)),
    ]);
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _primaryDeep.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.sansita(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: _primaryDeep.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _primaryDeep.withValues(alpha: 0.6), size: 17),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.sansita(
            fontSize: 12, color: _primaryDeep.withValues(alpha: 0.45))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.sansita(
            fontSize: 15, fontWeight: FontWeight.w600, color: _primaryDeep)),
      ])),
    ]);
  }

  Widget _buildDivider() => Divider(height: 20, color: _primaryDeep.withValues(alpha: 0.07));

  Widget _buildTarifaCard(IconData icon, String title, dynamic precio, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color.shade600, size: 22),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.sansita(fontSize: 13, color: color.shade800)),
        const SizedBox(height: 3),
        Text(precio != null ? '\$$precio/hr' : 'N/A',
            style: GoogleFonts.sansita(
                fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
      ]),
    );
  }

  List<Widget> _buildDiasChips(dynamic dias) {
    final List<int> diasAbierto = dias != null
        ? List<int>.from(dias.map((e) => int.parse(e.toString())))
        : [];
    final nombres = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};
    return nombres.entries.map((e) {
      final isOpen = diasAbierto.contains(e.key);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: isOpen ? _primaryDeep : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10)),
        child: Text(e.value, style: GoogleFonts.sansita(
            color: isOpen ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }).toList();
  }

  String _formatDate(String? inicio, String? fin) {
    if (inicio == null) return '';
    try {
      final d1 = DateTime.parse(inicio);
      final s = '${d1.day}/${d1.month}/${d1.year}';
      if (fin != null && fin.isNotEmpty) {
        final d2 = DateTime.parse(fin);
        return '$s – ${d2.day}/${d2.month}/${d2.year}';
      }
      return s;
    } catch (_) {
      return inicio;
    }
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(label, style: GoogleFonts.sansita(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: _primaryDeep.withValues(alpha: 0.65))),
      ),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: _primaryDeep.withValues(alpha: 0.45), size: 19),
          filled: true,
          fillColor: _primaryDeep.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _primaryDeep.withValues(alpha: 0.08))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _primaryDeep.withValues(alpha: 0.25), width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.3))),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
      ),
    ]);
  }
}
