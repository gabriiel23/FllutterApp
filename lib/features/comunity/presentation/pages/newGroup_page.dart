import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final Color _primaryDeep = const Color(0xFF19382F);

  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final List<Map<String, String>> _selectedPlayers = [];
  List<Map<String, dynamic>> _allPlayers = [];

  File? _imageFile;
  bool _isPublic = true;
  bool _isLoading = false;

  final String apiUrl = '${Config.baseUrl}/api/grupo';
  final String playersApiUrl = '${Config.baseUrl}/api/usuarios';

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentUserId = prefs.getString('userId'));
  }

  Future<void> _fetchPlayers() async {
    try {
      var response = await http.get(Uri.parse(playersApiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allPlayers =
              data.map((p) => p as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {
      _showSnack('Error al cargar jugadores');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita()),
      backgroundColor: isError ? Colors.red.shade400 : _primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    final desc = _groupDescriptionController.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      _showSnack('Completa el nombre y la descripción', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final userId = prefs.getString('userId');

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre'] = name;
      request.fields['descripcion'] = desc;
      request.fields['privacidad'] = _isPublic ? 'publico' : 'privado';
      if (userId != null) request.fields['admin'] = userId;
      request.fields['integrantes'] =
          jsonEncode(_selectedPlayers.map((p) => p['id']!).toList());
      if (_imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('foto', _imageFile!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        _showSnack('¡Grupo creado exitosamente!');
        Navigator.pop(context, true);
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Error al crear el grupo';
        _showSnack(error, isError: true);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showSnack('Error de conexión', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Foto del grupo ──
                      _buildImageSection(),
                      const SizedBox(height: 28),

                      // ── Info ──
                      _buildGroupLabel(
                          Icons.edit_rounded, 'Información del grupo'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _groupNameController,
                        hint: 'Ej: Los Galácticos FC',
                        icon: Icons.groups_rounded,
                        label: 'Nombre del grupo',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _groupDescriptionController,
                        hint: '¿De qué trata este grupo?',
                        icon: Icons.description_rounded,
                        label: 'Descripción',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),

                      // ── Privacidad ──
                      _buildGroupLabel(Icons.lock_rounded, 'Privacidad'),
                      const SizedBox(height: 12),
                      _buildPrivacySelector(),
                      const SizedBox(height: 28),

                      // ── Participantes ──
                      _buildGroupLabel(
                          Icons.person_add_rounded, 'Añadir participantes'),
                      const SizedBox(height: 4),
                      Text(
                        'Busca y agrega jugadores a tu grupo',
                        style: GoogleFonts.sansita(
                            fontSize: 12,
                            color: _primaryDeep.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 12),
                      _buildPlayerSearch(),
                      if (_selectedPlayers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSelectedPlayers(),
                      ],
                      const SizedBox(height: 36),

                      // ── Botón crear ──
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                  child: CircularProgressIndicator(color: _primaryDeep)),
            ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(children: [
                Material(
                  color: _primaryDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_rounded,
                            size: 22, color: _primaryDeep)),
                  ),
                ),
                const SizedBox(width: 24),
                Text('Nuevo Grupo',
                    style: GoogleFonts.sansita(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _primaryDeep,
                        letterSpacing: -0.5)),
              ]),
              const SizedBox(height: 6),
              Text('Crea un grupo y conecta con otros jugadores',
                  style: GoogleFonts.sansita(
                      fontSize: 14,
                      color: _primaryDeep.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── IMAGEN ────────────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _primaryDeep.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _primaryDeep.withValues(alpha: 0.12),
                        width: 2.5),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? Icon(Icons.groups_rounded,
                          size: 44,
                          color: _primaryDeep.withValues(alpha: 0.25))
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryDeep,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _imageFile == null
                ? 'Toca para agregar foto'
                : 'Toca para cambiar foto',
            style: GoogleFonts.sansita(
                fontSize: 12,
                color: _primaryDeep.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  // ── PRIVACIDAD ────────────────────────────────────────────────────────────
  Widget _buildPrivacySelector() {
    return Row(children: [
      Expanded(child: _buildPrivacyOption(true)),
      const SizedBox(width: 12),
      Expanded(child: _buildPrivacyOption(false)),
    ]);
  }

  Widget _buildPrivacyOption(bool isPublic) {
    final selected = _isPublic == isPublic;
    return GestureDetector(
      onTap: () => setState(() => _isPublic = isPublic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _primaryDeep : _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected
                  ? _primaryDeep
                  : _primaryDeep.withValues(alpha: 0.08)),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: _primaryDeep.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 20,
            color: selected
                ? Colors.white
                : _primaryDeep.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPublic ? 'Público' : 'Privado',
                      style: GoogleFonts.sansita(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : _primaryDeep)),
                  Text(
                    isPublic
                        ? 'Cualquiera puede unirse'
                        : 'Solo por invitación',
                    style: GoogleFonts.sansita(
                        fontSize: 11,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.7)
                            : _primaryDeep.withValues(alpha: 0.4)),
                  ),
                ]),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: Colors.white.withValues(alpha: 0.8), size: 18),
        ]),
      ),
    );
  }

  // ── BOTÓN PARA ABRIR MODAL DE PARTICIPANTES ─────────────────────────────────
  Widget _buildPlayerSearch() {
    return InkWell(
      onTap: _showAddParticipantsSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: _primaryDeep.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              'Seleccionar jugadores...',
              style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4), fontSize: 14),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down_rounded, color: _primaryDeep.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantsSheet() {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = _allPlayers.where((p) {
            final matches = p['nombre'].toString().toLowerCase().contains(query.toLowerCase());
            final isSelf = p['_id'].toString() == _currentUserId;
            return matches && !isSelf;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Text('Añadir Jugadores', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryDeep)),
                const SizedBox(height: 20),
                // Barra de búsqueda dentro del modal
                TextField(
                  onChanged: (v) => setSheetState(() => query = v),
                  style: GoogleFonts.sansita(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final id = p['_id'].toString();
                      final isSelected = _selectedPlayers.any((s) => s['id'] == id);
                      final avatarUrl = (p['avatar'] ?? '').toString();
                      final fullUrl = avatarUrl.startsWith('http') ? avatarUrl : (avatarUrl.isNotEmpty ? '${Config.baseUrl}$avatarUrl' : '');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundImage: fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null,
                          child: fullUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(p['nombre'] ?? '', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPlayers.removeWhere((s) => s['id'] == id);
                              } else {
                                _selectedPlayers.add({
                                  'id': id,
                                  'nombre': p['nombre'],
                                  'avatar': p['avatar'] ?? '',
                                });
                              }
                            });
                            setSheetState(() {}); // Actualizar modal
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.red.shade50 : _primaryDeep.withValues(alpha: 0.1),
                            foregroundColor: isSelected ? Colors.red : _primaryDeep,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isSelected ? 'Quitar' : 'Agregar', style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text('Listo', style: GoogleFonts.sansita(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── JUGADORES SELECCIONADOS ───────────────────────────────────────────────
  Widget _buildSelectedPlayers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedPlayers.length} seleccionado${_selectedPlayers.length != 1 ? 's' : ''}',
              style: GoogleFonts.sansita(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primaryDeep),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _selectedPlayers.map((player) {
            final avatarUrl = player['avatar'] ?? '';
            final fullUrl = avatarUrl.startsWith('http')
                ? avatarUrl
                : avatarUrl.isNotEmpty
                    ? '${Config.baseUrl}$avatarUrl'
                    : '';
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _primaryDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: _primaryDeep.withValues(alpha: 0.1)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      _primaryDeep.withValues(alpha: 0.12),
                  backgroundImage:
                      fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null,
                  child: fullUrl.isEmpty
                      ? Text(
                          (player['nombre'] ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.sansita(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _primaryDeep),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  player['nombre']!.split(' ')[0],
                  style: GoogleFonts.sansita(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryDeep),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPlayers.remove(player)),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 11, color: _primaryDeep),
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _createGroup,
        icon: const Icon(Icons.check_rounded, size: 20),
        label: Text('Crear grupo',
            style: GoogleFonts.sansita(
                fontSize: 17, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _buildGroupLabel(IconData icon, String label) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: _primaryDeep),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: GoogleFonts.sansita(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _primaryDeep,
              letterSpacing: -0.2)),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String label,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.sansita(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primaryDeep.withValues(alpha: 0.45))),
      const SizedBox(height: 7),
      Container(
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.sansita(
              fontSize: 15,
              color: _primaryDeep,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sansita(
                color: _primaryDeep.withValues(alpha: 0.3),
                fontSize: 14),
            prefixIcon: Icon(icon,
                size: 19,
                color: _primaryDeep.withValues(alpha: 0.45)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 15),
          ),
        ),
      ),
    ]);
  }
}
