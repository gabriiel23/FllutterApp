
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class GalleryPage extends StatefulWidget {
  final String jugadorId;
  final List<String> galeriaInicial;

  const GalleryPage({
    super.key,
    required this.jugadorId,
    required this.galeriaInicial,
  });

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final Color _primaryDeep = const Color(0xFF19382F);
  final ImagePicker _picker = ImagePicker();

  late List<String> _galeriaUrls; // fotos ya guardadas en el servidor
  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _galeriaUrls = List<String>.from(widget.galeriaInicial);
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('userToken'));
  }

  String _buildImageUrl(String url) {
    return url.startsWith('http') ? url : '${Config.baseUrl}$url';
  }

  // ── AGREGAR FOTOS ────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhotos() async {
    if (_galeriaUrls.length >= 6) {
      _showSnack('Ya tienes 6 fotos. Elimina alguna para agregar nuevas.');
      return;
    }

    final int maxPick = 6 - _galeriaUrls.length;
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final filesToUpload = picked.take(maxPick).toList();

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
          '${Config.baseUrl}/api/jugadores/${widget.jugadorId}/galeria');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      for (var xfile in filesToUpload) {
        request.files
            .add(await http.MultipartFile.fromPath('fotos', xfile.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> nuevaGaleria = data['jugador']['galeria'];
        if (mounted) {
          setState(() {
            _galeriaUrls = List<String>.from(nuevaGaleria);
          });
        }
        _showSnack('¡Fotos agregadas exitosamente!');
      } else {
        final body = json.decode(response.body);
        throw Exception(body['mensaje'] ?? 'Error al subir fotos');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── ELIMINAR FOTO ────────────────────────────────────────────────────────
  Future<void> _deletePhoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar foto?',
            style: GoogleFonts.sansita(
                fontWeight: FontWeight.w800, color: _primaryDeep)),
        content: Text('Esta acción no se puede deshacer.',
            style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Eliminar', style: GoogleFonts.sansita()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
          '${Config.baseUrl}/api/jugadores/${widget.jugadorId}/galeria/$index');
      final response = await http.delete(
        uri,
        headers: {
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> nuevaGaleria = data['jugador']['galeria'];
        if (mounted) {
          setState(() {
            _galeriaUrls = List<String>.from(nuevaGaleria);
          });
        }
        _showSnack('Foto eliminada');
      } else {
        final body = json.decode(response.body);
        throw Exception(body['mensaje'] ?? 'Error al eliminar foto');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── INTERCAMBIAR FOTO (eliminar + subir nueva) ───────────────────────────
  Future<void> _swapPhoto(int index) async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Eliminar la foto actual
      final deleteUri = Uri.parse(
          '${Config.baseUrl}/api/jugadores/${widget.jugadorId}/galeria/$index');
      final deleteRes = await http.delete(deleteUri, headers: {
        if (_token != null) 'Authorization': 'Bearer $_token',
      });

      if (deleteRes.statusCode != 200) {
        throw Exception('Error al eliminar foto antigua');
      }

      // 2. Subir la nueva foto
      final addUri = Uri.parse(
          '${Config.baseUrl}/api/jugadores/${widget.jugadorId}/galeria');
      final request = http.MultipartRequest('POST', addUri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files
          .add(await http.MultipartFile.fromPath('fotos', picked.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> nuevaGaleria = data['jugador']['galeria'];
        if (mounted) {
          setState(() {
            _galeriaUrls = List<String>.from(nuevaGaleria);
          });
        }
        _showSnack('¡Foto actualizada!');
      } else {
        throw Exception('Error al subir nueva foto');
      }
    } catch (e) {
      _showSnack('Error: $e');
      // Refrescar estado actual
      _refreshGallery();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshGallery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId');
      final tok = prefs.getString('userToken');
      if (uid == null || tok == null) return;

      final res = await http.get(
        Uri.parse('${Config.baseUrl}/api/jugadores/usuario/$uid'),
        headers: {'Authorization': 'Bearer $tok'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        final List<dynamic> g = data['galeria'] ?? [];
        setState(() => _galeriaUrls = List<String>.from(g));
      }
    } catch (_) {}
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

  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            Text('Opciones de foto',
                style: GoogleFonts.sansita(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryDeep)),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Intercambiar foto',
              color: _primaryDeep,
              onTap: () {
                Navigator.pop(ctx);
                _swapPhoto(index);
              },
            ),
            const SizedBox(height: 10),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Eliminar foto',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(ctx);
                _deletePhoto(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Text(label,
                  style: GoogleFonts.sansita(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryDeep))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contador
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_galeriaUrls.length}/6 fotos',
                              style: GoogleFonts.sansita(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryDeep.withValues(alpha: 0.5)),
                            ),
                            if (_galeriaUrls.length < 6)
                              Material(
                                color: _primaryDeep,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: _pickAndUploadPhotos,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: Colors.white,
                                            size: 18),
                                        const SizedBox(width: 6),
                                        Text('Agregar',
                                            style: GoogleFonts.sansita(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Grid de fotos
                        if (_galeriaUrls.isEmpty)
                          _buildEmptyState()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _galeriaUrls.length +
                                (_galeriaUrls.length < 6 ? 1 : 0),
                            itemBuilder: (_, i) {
                              // Última celda = botón agregar
                              if (i == _galeriaUrls.length) {
                                return _buildAddTile();
                              }
                              return _buildPhotoTile(i);
                            },
                          ),

                        const SizedBox(height: 24),

                        // Hint
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _primaryDeep.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _primaryDeep.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18,
                                  color: _primaryDeep.withValues(alpha: 0.5)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Toca una foto para ver las opciones de intercambio o eliminación.',
                                  style: GoogleFonts.sansita(
                                      fontSize: 12,
                                      color:
                                          _primaryDeep.withValues(alpha: 0.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  const SizedBox(width: 12),
                  Text(
                    'Mi Galería',
                    style: GoogleFonts.sansita(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gestiona tus fotos de jugador · máx. 6',
                style: GoogleFonts.sansita(
                    fontSize: 14,
                    color: _primaryDeep.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    final url = _buildImageUrl(_galeriaUrls[index]);
    return GestureDetector(
      onTap: () => _showPhotoOptions(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    color: _primaryDeep.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryDeep.withValues(alpha: 0.4)),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: _primaryDeep.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.broken_image_rounded,
                    color: _primaryDeep.withValues(alpha: 0.3)),
              ),
            ),
          ),
          // Overlay opciones
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _pickAndUploadPhotos,
      child: Container(
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _primaryDeep.withValues(alpha: 0.15),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: _primaryDeep.withValues(alpha: 0.4), size: 28),
            const SizedBox(height: 6),
            Text('Agregar',
                style: GoogleFonts.sansita(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primaryDeep.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              size: 52, color: _primaryDeep.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Sin fotos aún',
              style: GoogleFonts.sansita(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryDeep.withValues(alpha: 0.3))),
          const SizedBox(height: 6),
          Text('Toca "Agregar" para subir tus primeras fotos',
              style: GoogleFonts.sansita(
                  fontSize: 13,
                  color: _primaryDeep.withValues(alpha: 0.22)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
