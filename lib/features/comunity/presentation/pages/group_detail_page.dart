import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterapp/config.dart';

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final Color _primaryDeep = const Color(0xFF19382F);
  String? _myUserId;
  String? _myToken;
  late Map<String, dynamic> _groupData;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _groupData = widget.group;
    _loadSession();
    _refreshGroup(); // Refrescar para obtener solicitudes pobladas
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myUserId = prefs.getString('userId');
      _myToken = prefs.getString('userToken');
    });
  }

  bool get _isAdmin => _myUserId != null && _groupData['admin'] != null && 
      (_groupData['admin'] is Map ? _groupData['admin']['_id'] : _groupData['admin']) == _myUserId;

  bool get _isMember => _myUserId != null && (_groupData['integrantes'] as List).any((m) => 
      (m is Map ? m['_id'] : m) == _myUserId);

  String get _fotoUrl {
    final foto = _groupData['foto'];
    return (foto != null && foto.toString().isNotEmpty)
        ? (foto.toString().startsWith('http') ? foto.toString() : '${Config.baseUrl}$foto')
        : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=600&auto=format&fit=crop';
  }

  Future<void> _refreshGroup() async {
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}'));
      if (res.statusCode == 200) {
        setState(() => _groupData = json.decode(res.body));
      }
    } catch (_) {}
  }


  Future<void> _addGalleryImages() async {
    if (!_isAdmin) return;
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
    
    if (images.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}/galeria'));
      request.headers['Authorization'] = 'Bearer $_myToken';
      
      for (var img in images) {
        request.files.add(await http.MultipartFile.fromPath('fotos', img.path));
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imágenes subidas a la galería')));
        _refreshGroup();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir imágenes')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainInfo(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.people_rounded, 'Integrantes (${(_groupData['integrantes'] as List).length})'),
                      const SizedBox(height: 16),
                      _buildMembersList(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.photo_library_rounded, 'Galería del Grupo'),
                      const SizedBox(height: 16),
                      _buildGallery(),
                      const SizedBox(height: 100), // Espacio para el botón de abajo
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primaryDeep),
                    const SizedBox(height: 16),
                    Text('Subiendo fotos...', style: GoogleFonts.sansita(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton.extended(
        onPressed: _addGalleryImages,
        backgroundColor: _primaryDeep,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text('Añadir Fotos', style: GoogleFonts.sansita(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      bottomSheet: !_isAdmin ? _buildJoinButton() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: _primaryDeep,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: _showAdminOptions,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(_fotoUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isPending => _myUserId != null && (_groupData['solicitudes'] as List? ?? []).any((s) => 
      (s is Map ? s['_id'] : s) == _myUserId);

  void _showAdminOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Text('Opciones de Administrador', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDeep)),
            const SizedBox(height: 24),
            _buildOptionItem(Icons.edit_rounded, 'Editar información', () {
              Navigator.pop(ctx);
              _showEditSheet();
            }),
            _buildOptionItem(Icons.people_rounded, 'Gestionar miembros', () {
              Navigator.pop(ctx);
              _showManageMembersDialog();
            }),
            _buildOptionItem(Icons.notification_important_rounded, 'Solicitudes de unión', () {
              Navigator.pop(ctx);
              _showRequestsSheet();
            }),
            const Divider(height: 32),
            _buildOptionItem(Icons.delete_forever_rounded, 'Eliminar grupo', () {
              Navigator.pop(ctx);
              _confirmDeleteGroup();
            }, isDestructive: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRequestsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Solicitudes Pendientes', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryDeep)),
            const SizedBox(height: 20),
            Expanded(
              child: (_groupData['solicitudes'] as List).isEmpty 
                ? Center(child: Text('No hay solicitudes pendientes', style: GoogleFonts.sansita(color: Colors.grey)))
                : ListView.builder(
                    itemCount: (_groupData['solicitudes'] as List).length,
                    itemBuilder: (_, i) {
                      final dynamic req = _groupData['solicitudes'][i];
                      
                      // Si por alguna razón los datos no están poblados todavía (es un String ID)
                      if (req is! Map) {
                        return const ListTile(title: Text('Cargando solicitud...'));
                      }

                      final avatarUrl = req['avatar']?.toString() ?? '';
                      final fullAvatar = avatarUrl.isNotEmpty 
                        ? (avatarUrl.startsWith('http') ? avatarUrl : '${Config.baseUrl}$avatarUrl')
                        : '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: fullAvatar.isNotEmpty ? NetworkImage(fullAvatar) : null,
                          child: fullAvatar.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text('${req['nombre'] ?? 'Usuario'} ${req['apellidos'] ?? ''}', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _gestionarSolicitud(req['_id'], 'aceptar')),
                            IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => _gestionarSolicitud(req['_id'], 'rechazar')),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gestionarSolicitud(String usuarioId, String accion) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}/solicitud/$usuarioId'),
        headers: {'Authorization': 'Bearer $_myToken', 'Content-Type': 'application/json'},
        body: json.encode({'accion': accion}),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        _refreshGroup();
        Navigator.pop(context);
        _showRequestsSheet();
      }
    } catch (_) {}
  }

  Widget? _buildJoinButton() {
    if (_isMember) return null;

    String label = _groupData['privacidad'] == 'publico' ? 'Unirse al grupo' : 'Solicitar unirse al grupo';
    if (_isPending) label = 'Solicitud Pendiente';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isPending ? null : _unirseGrupo,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPending ? Colors.grey : _primaryDeep,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label, style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _unirseGrupo() async {
    setState(() => _isUploading = true);
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}/unirse'),
        headers: {'Authorization': 'Bearer $_myToken'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        _refreshGroup();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al unirse')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildOptionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : _primaryDeep;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: _groupData['nombre']);
    final descCtrl = TextEditingController(text: _groupData['descripcion']);
    bool public = _groupData['privacidad'] != 'privado';
    File? tempImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Editar Grupo', style: GoogleFonts.sansita(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryDeep)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _primaryDeep.withValues(alpha: 0.05),
                          border: Border.all(color: _primaryDeep.withValues(alpha: 0.1), width: 3),
                          image: tempImage != null
                              ? DecorationImage(image: FileImage(tempImage!), fit: BoxFit.cover)
                              : DecorationImage(image: NetworkImage(_fotoUrl), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (picked != null) setSheetState(() => tempImage = File(picked.path));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _primaryDeep, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('Nombre del Grupo'),
                const SizedBox(height: 8),
                _buildSheetTextField(nameCtrl, 'Ej: Los Crack FC', Icons.groups_rounded),
                const SizedBox(height: 20),
                _buildFieldLabel('Descripción'),
                const SizedBox(height: 8),
                _buildSheetTextField(descCtrl, 'Describe tu grupo...', Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryDeep.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(public ? Icons.public_rounded : Icons.lock_rounded, color: _primaryDeep),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(public ? 'Grupo Público' : 'Grupo Privado', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: _primaryDeep)),
                            Text(public ? 'Cualquiera puede unirse' : 'Solo por invitación', style: GoogleFonts.sansita(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: public,
                        activeThumbColor: _primaryDeep,
                        onChanged: (v) => setSheetState(() => public = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveGroupEdits(nameCtrl.text, descCtrl.text, public ? 'publico' : 'privado', tempImage);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryDeep, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('Guardar Cambios', style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryDeep.withValues(alpha: 0.5)));
  }

  Widget _buildSheetTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.sansita(color: _primaryDeep),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryDeep.withValues(alpha: 0.3)),
        filled: true,
        fillColor: _primaryDeep.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _saveGroupEdits(String name, String desc, String privacy, File? newPhoto) async {
    setState(() => _isUploading = true);
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}'));
      request.headers['Authorization'] = 'Bearer $_myToken';
      request.fields['nombre'] = name;
      request.fields['descripcion'] = desc;
      request.fields['privacidad'] = privacy;
      
      if (newPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', newPhoto.path));
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        if (!mounted) return;
        _refreshGroup();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grupo actualizado exitosamente')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar grupo')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showManageMembersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Gestionar Miembros', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryDeep)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: (_groupData['integrantes'] as List).length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final member = _groupData['integrantes'][i];
                  final isAdminMember = member['_id'] == (_groupData['admin'] is Map ? _groupData['admin']['_id'] : _groupData['admin']);
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: member['avatar'] != null 
                          ? NetworkImage(member['avatar'].startsWith('http') ? member['avatar'] : '${Config.baseUrl}${member['avatar']}')
                          : null,
                      child: member['avatar'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text('${member['nombre']} ${member['apellidos']}', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                    subtitle: Text(isAdminMember ? 'Administrador' : 'Miembro', style: GoogleFonts.sansita(fontSize: 12)),
                    trailing: (!isAdminMember) ? IconButton(
                      icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                      onPressed: () => _removeMember(member['_id']),
                    ) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(String usuarioId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar miembro', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
        content: Text('¿Seguro que quieres sacar a este usuario del grupo?', style: GoogleFonts.sansita()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}/integrante/$usuarioId'),
        headers: {'Authorization': 'Bearer $_myToken'},
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        _refreshGroup();
        Navigator.pop(context); // Cerrar bottom sheet
        _showManageMembersDialog(); // Reabrir para ver cambios
      }
    } catch (_) {}
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar Grupo', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('¿Estás completamente seguro? Esta acción no se puede deshacer y el grupo desaparecerá para todos.', style: GoogleFonts.sansita()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    setState(() => _isUploading = true);
    try {
      final res = await http.delete(
        Uri.parse('${Config.baseUrl}/api/grupo/${_groupData['_id']}'),
        headers: {'Authorization': 'Bearer $_myToken'},
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // Volver con señal de refresco
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grupo eliminado')));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildMainInfo() {
    final bool isPublic = _groupData['privacidad'] != 'privado';
    final admin = _groupData['admin'] is Map ? _groupData['admin'] : null;
    final adminName = admin != null ? '${admin['nombre']} ${admin['apellidos']}' : 'Admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _groupData['nombre']?.toUpperCase() ?? 'GRUPO',
                style: GoogleFonts.sansita(fontSize: 28, fontWeight: FontWeight.w900, color: _primaryDeep),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryDeep.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 14, color: _primaryDeep),
                  const SizedBox(width: 6),
                  Text(isPublic ? 'Público' : 'Privado', 
                      style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryDeep)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _groupData['descripcion'] ?? 'Sin descripción',
          style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep.withValues(alpha: 0.6), height: 1.4),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: _primaryDeep.withValues(alpha: 0.1),
              backgroundImage: (admin != null && admin['avatar'] != null) 
                  ? NetworkImage(admin['avatar'].startsWith('http') ? admin['avatar'] : '${Config.baseUrl}${admin['avatar']}')
                  : null,
              child: (admin == null || admin['avatar'] == null) ? Icon(Icons.person, size: 12, color: _primaryDeep) : null,
            ),
            const SizedBox(width: 8),
            Text('Administrado por ', style: GoogleFonts.sansita(fontSize: 13, color: Colors.grey)),
            Text(adminName, style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryDeep)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryDeep),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDeep)),
      ],
    );
  }

  Widget _buildMembersList() {
    final members = _groupData['integrantes'] as List;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final m = members[i] is Map ? members[i] : {};
          final name = m['nombre'] ?? 'User';
          final av = m['avatar'];
          final avUrl = (av != null) ? (av.toString().startsWith('http') ? av.toString() : '${Config.baseUrl}$av') : null;

          return Column(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _primaryDeep.withValues(alpha: 0.05),
                backgroundImage: avUrl != null ? NetworkImage(avUrl) : null,
                child: avUrl == null ? Icon(Icons.person, color: _primaryDeep.withValues(alpha: 0.3)) : null,
              ),
              const SizedBox(height: 4),
              Text(name, style: GoogleFonts.sansita(fontSize: 11, color: _primaryDeep.withValues(alpha: 0.7))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGallery() {
    final galeria = _groupData['galeria'] as List? ?? [];
    if (galeria.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, color: _primaryDeep.withValues(alpha: 0.2), size: 40),
            const SizedBox(height: 12),
            Text('No hay fotos en la galería', style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.3))),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: galeria.length,
      itemBuilder: (_, i) {
        final url = galeria[i].toString().startsWith('http') ? galeria[i] : '${Config.baseUrl}${galeria[i]}';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.cover),
        );
      },
    );
  }
}
