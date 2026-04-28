import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterapp/config.dart';
import 'package:flutterapp/services/auth_service.dart';
import 'package:flutterapp/features/profile/presentation/pages/profilePlayer_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/gallery_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userId;
  String? token;
  String? userRol;
  Map<String, dynamic>? jugadorData;

  final Color _primaryDeep = const Color(0xFF19382F);

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      token = prefs.getString('userToken');
      userRol = prefs.getString('userRol');

      if (userId == null || token == null) throw Exception("Sin credenciales");

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/usuario/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) setState(() { userData = json.decode(response.body); isLoading = false; });

        if (userRol == 'jugador') {
          final jRes = await http.get(
            Uri.parse('${Config.baseUrl}/api/jugadores/usuario/$userId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (jRes.statusCode == 200 && mounted) {
            setState(() => jugadorData = json.decode(jRes.body));
          }
        }
      } else {
        throw Exception('Error al obtener datos');
      }
    } catch (_) {
      if (mounted) setState(() { isLoading = false; userData = null; });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || userId == null || token == null) return;

    setState(() => isLoading = true);
    try {
      final authService = AuthService();
      await authService.updateUser(
        userId!,
        token!,
        userData!['nombre'] ?? '',
        userData!['apellidos'] ?? '',
        userData!['nacionalidad'] ?? '',
        userData!['telefono'] ?? '',
        File(pickedFile.path),
      );
      await fetchUserData(); // Refresh data with new avatar
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al actualizar foto: $e', style: GoogleFonts.sansita()),
          backgroundColor: _primaryDeep,
        ));
      }
    }
  }

  // ── BOTTOM SHEET EDICIÓN ──────────────────────────────────────────────────
  void _showEditBottomSheet() {
    final nombreCtrl = TextEditingController(text: userData!['nombre']);
    final apellidosCtrl = TextEditingController(text: userData!['apellidos'] ?? '');
    final nacionalidadCtrl = TextEditingController(text: userData!['nacionalidad'] ?? '');
    final telefonoCtrl = TextEditingController(text: userData!['telefono'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_rounded, size: 18, color: _primaryDeep),
                  ),
                  const SizedBox(width: 12),
                  Text('Editar información',
                      style: GoogleFonts.sansita(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryDeep)),
                ],
              ),
              const SizedBox(height: 20),
              _buildSheetField(nombreCtrl, 'Nombres', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildSheetField(apellidosCtrl, 'Apellidos', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildSheetField(nacionalidadCtrl, '¿De dónde eres?', Icons.location_on_rounded),
              const SizedBox(height: 12),
              _buildSheetField(telefonoCtrl, 'Teléfono', Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setSheet(() => isSaving = true);
                          try {
                            final authService = AuthService();
                            await authService.updateUser(
                                userId!, token!, nombreCtrl.text,
                                apellidosCtrl.text, nacionalidadCtrl.text,
                                telefonoCtrl.text, null);
                            if (mounted) {
                              Navigator.pop(ctx);
                              fetchUserData();
                            }
                          } catch (e) {
                            setSheet(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e', style: GoogleFonts.sansita()),
                                  backgroundColor: _primaryDeep,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Guardar cambios',
                          style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.35)),
          prefixIcon: Icon(icon, color: _primaryDeep.withValues(alpha: 0.45), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  // ── HELPERS CARTA FIFA ────────────────────────────────────────────────────
  int get _overallRating {
    if (jugadorData == null) return 50;
    final attrs = jugadorData!['atributos'] as Map<String, dynamic>?;
    if (attrs == null || attrs.isEmpty) return 50;
    int sum = 0, count = 0;
    for (var a in _getCurrentAttributesList()) {
      if (attrs[a] != null) { sum += (attrs[a] as num).toInt(); count++; }
    }
    return count > 0 ? (sum / count).round() : 50;
  }

  List<String> _getCurrentAttributesList() {
    if (jugadorData == null) return [];
    return jugadorData!['posicion'] == 'Portero'
        ? ['Reflejos', 'Saque', 'Manejo', 'Estirada', 'Velocidad', 'Posicionamiento']
        : ['Ritmo', 'Tiro', 'Pase', 'Regate', 'Defensa', 'Físico'];
  }

  String _getPosAbbreviation() {
    switch (jugadorData?['posicion']) {
      case 'Portero': return 'POR';
      case 'Defensa': return 'DEF';
      case 'Mediocampista': return 'MED';
      case 'Delantero': return 'DEL';
      default: return '-';
    }
  }

  Color _getAttrColor(int v) {
    if (v >= 80) return Colors.green.shade600;
    if (v >= 60) return const Color(0xFFF59E0B);
    return Colors.red.shade400;
  }

  String _avatarUrl() {
    if (userData?['avatar'] == null) {
      return 'https://w7.pngwing.com/pngs/1008/377/png-transparent-computer-icons-avatar-user-profile-avatar-heroes-black-hair-computer.png';
    }
    return userData!['avatar'].startsWith('http')
        ? userData!['avatar']
        : '${Config.baseUrl}${userData!['avatar']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryDeep))
          : userData == null
              ? const Center(child: Text("Error al cargar perfil"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                        child: Column(
                          children: [
                            _buildIdentityCard(),
                            const SizedBox(height: 28),
                            _buildInfoSection(),
                            const SizedBox(height: 28),
                            if (jugadorData != null) ...[
                              _buildPlayerSection(),
                              const SizedBox(height: 28),
                              _buildGallerySection(),
                            ] else if (userRol == 'jugador')
                              _buildCreatePlayerBtn(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(width: 42, height: 42,
                        child: Icon(Icons.settings_outlined, size: 22, color: _primaryDeep)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.account_circle_rounded, size: 24, color: _primaryDeep),
                  ),
                  const SizedBox(width: 12),
                  Text('Mi Perfil',
                    style: GoogleFonts.sansita(fontSize: 34, fontWeight: FontWeight.w800,
                        color: _primaryDeep, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Tus datos y estadísticas',
                style: GoogleFonts.sansita(fontSize: 15,
                    color: _primaryDeep.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── CARD IDENTIDAD ────────────────────────────────────────────────────────
  Widget _buildIdentityCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.06),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryDeep.withValues(alpha: 0.15), width: 3),
                  image: DecorationImage(
                      image: NetworkImage(_avatarUrl()), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: _primaryDeep, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "${userData!['nombre']} ${userData!['apellidos'] ?? ''}".trim(),
            style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryDeep),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(userData!['email'] ?? '',
            style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(userRol?.toUpperCase() ?? 'USUARIO',
              style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryDeep)),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN INFO PERSONAL ─────────────────────────────────────────────────
  Widget _buildInfoSection() {
    final createdAt = userData!['fechaRegistro'] != null
        ? DateTime.parse(userData!['fechaRegistro']).toString().split(' ')[0]
        : "N/A";

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(Icons.person_outline_rounded, 'Información personal'),
            Material(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _showEditBottomSheet,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(width: 36, height: 36,
                  child: Icon(Icons.edit_rounded, size: 17, color: Color(0xFF19382F))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
            boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.location_on_rounded, 'Procedencia',
                  userData!['nacionalidad'] ?? 'No especificado'),
              _buildDivider(),
              _buildInfoRow(Icons.phone_rounded, 'Teléfono',
                  userData!['telefono'] ?? 'No especificado'),
              _buildDivider(),
              _buildInfoRow(Icons.calendar_today_rounded, 'Miembro desde', createdAt),
            ],
          ),
        ),
      ],
    );
  }

  // ── SECCIÓN JUGADOR ───────────────────────────────────────────────────────
  Widget _buildPlayerSection() {
    final attrs = _getCurrentAttributesList();
    final atributos = jugadorData!['atributos'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(Icons.sports_soccer_rounded, 'Perfil de jugador'),
            Material(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProfilePlayerPage(initialData: jugadorData)),
                ).then((_) => fetchUserData()),
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(width: 36, height: 36,
                  child: Icon(Icons.edit_rounded, size: 17, color: Color(0xFF19382F))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Card resumen
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
            boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Overall grande
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5C07B), Color(0xFFC49A45)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFFC49A45).withValues(alpha: 0.3),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_overallRating',
                      style: GoogleFonts.sansita(fontSize: 30, fontWeight: FontWeight.w900,
                          color: Colors.black87, height: 1)),
                    Text(_getPosAbbreviation(),
                      style: GoogleFonts.sansita(fontSize: 13,
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Info compacta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.accessibility_new_rounded, 'Posición',
                        jugadorData!['posicion'] ?? '-'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.height_rounded, 'Estatura',
                        '${jugadorData!['estatura'] ?? '-'} cm'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.cake_rounded, 'Edad',
                        '${jugadorData!['edad'] ?? '-'} años'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid de atributos
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
            boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atributos técnicos',
                style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.w800,
                    color: _primaryDeep)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10,
                  mainAxisSpacing: 10, childAspectRatio: 1.4,
                ),
                itemCount: attrs.length,
                itemBuilder: (_, i) {
                  final attr = attrs[i];
                  final val = (atributos[attr] as num?)?.toInt() ?? 50;
                  final color = _getAttrColor(val);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$val',
                          style: GoogleFonts.sansita(fontSize: 22,
                              fontWeight: FontWeight.w900, color: color, height: 1)),
                        const SizedBox(height: 3),
                        Text(attr,
                          style: GoogleFonts.sansita(fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _primaryDeep.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SECCIÓN GALERÍA ───────────────────────────────────────────────────────
  Widget _buildGallerySection() {
    final galeria = (jugadorData!['galeria'] as List<dynamic>?) ?? [];
    final jugadorId = jugadorData!['_id'] as String?;

    void goToGallery() {
      if (jugadorId == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GalleryPage(
            jugadorId: jugadorId,
            galeriaInicial: galeria.map((e) => e.toString()).toList(),
          ),
        ),
      ).then((_) => fetchUserData());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(Icons.photo_library_rounded, 'Galería'),
            Material(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: goToGallery,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.edit_rounded, size: 17,
                      color: Color(0xFF19382F)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (galeria.isEmpty)
          GestureDetector(
            onTap: goToGallery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: _primaryDeep.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryDeep.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 44, color: _primaryDeep.withValues(alpha: 0.2)),
                  const SizedBox(height: 10),
                  Text('Sin fotos aún',
                    style: GoogleFonts.sansita(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primaryDeep.withValues(alpha: 0.3))),
                  const SizedBox(height: 4),
                  Text('Toca aquí para agregar fotos a tu galería',
                    style: GoogleFonts.sansita(fontSize: 12,
                        color: _primaryDeep.withValues(alpha: 0.25)),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: galeria.length,
            itemBuilder: (_, i) {
              final imgUrl = galeria[i].toString().startsWith('http')
                  ? galeria[i].toString()
                  : '${Config.baseUrl}${galeria[i]}';
              return GestureDetector(
                onTap: goToGallery,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(imgUrl, fit: BoxFit.cover),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreatePlayerBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfilePlayerPage()),
        ).then((_) => fetchUserData()),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDeep, foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text('Crear perfil de jugador',
            style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _primaryDeep),
        ),
        const SizedBox(width: 10),
        Text(title,
          style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800,
              color: _primaryDeep, letterSpacing: -0.3)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primaryDeep.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: GoogleFonts.sansita(fontSize: 11,
                  color: _primaryDeep.withValues(alpha: 0.4))),
            Text(value,
              style: GoogleFonts.sansita(fontSize: 14,
                  fontWeight: FontWeight.bold, color: _primaryDeep)),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(
      height: 24, color: _primaryDeep.withValues(alpha: 0.06));
}
