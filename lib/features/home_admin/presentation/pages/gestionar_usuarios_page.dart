import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';
import 'package:google_fonts/google_fonts.dart';

class GestionarUsuariosPage extends StatefulWidget {
  const GestionarUsuariosPage({Key? key}) : super(key: key);

  @override
  _GestionarUsuariosPageState createState() => _GestionarUsuariosPageState();
}

class _GestionarUsuariosPageState extends State<GestionarUsuariosPage> {
  List<dynamic> _usuarios = [];
  List<dynamic> _usuariosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filtroRol = 'Todos';

  final Color _primaryDeep = const Color(0xFF19382F);

  final List<String> _roles = [
    'Todos',
    'jugador',
    'administrador',
    'superadmin'
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _usuariosFiltrados = _usuarios.where((u) {
        final matchNombre = (u['nombre'] ?? '').toLowerCase().contains(query);
        final matchEmail = (u['email'] ?? '').toLowerCase().contains(query);
        final matchRol = _filtroRol == 'Todos' || u['rol'] == _filtroRol;
        return (matchNombre || matchEmail) && matchRol;
      }).toList();
    });
  }

  void _aplicarFiltroRol(String rol) {
    setState(() => _filtroRol = rol);
    _filtrar();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/usuarios-protegidos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _usuarios = json.decode(response.body);
          _usuariosFiltrados = List.from(_usuarios);
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar usuarios');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error al cargar la lista de usuarios', isError: true);
    }
  }

  Future<void> _actualizarRol(String userId, String nuevoRol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/usuario/$userId/rol'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rol': nuevoRol}),
      );

      if (response.statusCode == 200) {
        _showSnack('Rol actualizado a $nuevoRol');
        _cargarUsuarios();
      } else {
        throw Exception('Error al actualizar rol');
      }
    } catch (_) {
      _showSnack('Error al actualizar el rol', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita()),
      backgroundColor: isError ? Colors.red.shade400 : _primaryDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _mostrarBottomSheetRol(dynamic usuario) {
    String rolSeleccionado = usuario['rol'] ?? 'jugador';

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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),

              // Encabezado
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primaryDeep.withValues(alpha: 0.1),
                  child: Text(
                    (usuario['nombre'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.sansita(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryDeep),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(usuario['nombre'] ?? 'Usuario',
                          style: GoogleFonts.sansita(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _primaryDeep)),
                      Text(usuario['email'] ?? '',
                          style: GoogleFonts.sansita(
                              fontSize: 13,
                              color: _primaryDeep.withValues(alpha: 0.45))),
                    ])),
              ]),
              const SizedBox(height: 24),

              Text('Selecciona el nuevo rol',
                  style: GoogleFonts.sansita(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primaryDeep.withValues(alpha: 0.5))),
              const SizedBox(height: 12),

              // Opciones de rol
              ..._roles.where((r) => r != 'Todos').map((rol) {
                final isSelected = rolSeleccionado == rol;
                final info = _getRolInfo(rol);
                return GestureDetector(
                  onTap: () => setSheet(() => rolSeleccionado = rol),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? info['color'].withValues(alpha: 0.08)
                          : _primaryDeep.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? info['color'].withValues(alpha: 0.4)
                            : _primaryDeep.withValues(alpha: 0.07),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: info['color'].withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(info['icon'] as IconData,
                            color: info['color'] as Color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(info['label'] as String,
                                style: GoogleFonts.sansita(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryDeep)),
                            Text(info['desc'] as String,
                                style: GoogleFonts.sansita(
                                    fontSize: 12,
                                    color:
                                        _primaryDeep.withValues(alpha: 0.45))),
                          ])),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: info['color'] as Color, size: 20),
                    ]),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (rolSeleccionado != (usuario['rol'] ?? 'jugador')) {
                      _actualizarRol(usuario['_id'], rolSeleccionado);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Guardar cambios',
                      style: GoogleFonts.sansita(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRolInfo(String rol) {
    switch (rol) {
      case 'superadmin':
        return {
          'label': 'SuperAdmin',
          'desc': 'Acceso total al sistema',
          'icon': Icons.shield_rounded,
          'color': Colors.red.shade400,
        };
      case 'administrador':
        return {
          'label': 'Administrador',
          'desc': 'Gestiona espacios deportivos',
          'icon': Icons.manage_accounts_rounded,
          'color': Colors.orange.shade600,
        };
      default:
        return {
          'label': 'Jugador',
          'desc': 'Puede reservar canchas',
          'icon': Icons.sports_soccer_rounded,
          'color': Colors.blue.shade500,
        };
    }
  }

  Color _getRolColor(String? rol) {
    switch (rol) {
      case 'superadmin':
        return Colors.red.shade400;
      case 'administrador':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade500;
    }
  }

  String _getRolLabel(String? rol) {
    switch (rol) {
      case 'superadmin':
        return 'SuperAdmin';
      case 'administrador':
        return 'Admin';
      default:
        return 'Jugador';
    }
  }

  // ── CONTADORES POR ROL ────────────────────────────────────────────────────
  int _countByRol(String rol) => _usuarios.where((u) => u['rol'] == rol).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          if (!_isLoading) ...[
            _buildMetricas(),
            _buildSearchBar(),
            _buildFiltrosRol(),
          ],
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [],
              ),
              const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Text('Usuarios',
                    style: GoogleFonts.sansita(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _primaryDeep,
                        letterSpacing: -0.5)),
                Spacer(),
                Material(
                  color: _primaryDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _isLoading = true);
                      _cargarUsuarios();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.refresh_rounded,
                            size: 22, color: _primaryDeep)),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Gestiona roles y permisos de los usuarios',
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

  // ── MÉTRICAS ──────────────────────────────────────────────────────────────
  Widget _buildMetricas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(children: [
        _buildMetricChip('Total', '${_usuarios.length}', _primaryDeep),
        const SizedBox(width: 8),
        _buildMetricChip(
            'Jugadores', '${_countByRol('jugador')}', Colors.blue.shade500),
        const SizedBox(width: 8),
        _buildMetricChip('Admins', '${_countByRol('administrador')}',
            Colors.orange.shade600),
        const SizedBox(width: 8),
        _buildMetricChip(
            'Super', '${_countByRol('superadmin')}', Colors.red.shade400),
      ]),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.sansita(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.sansita(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── BUSCADOR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _primaryDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.sansita(fontSize: 15, color: _primaryDeep),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o correo...',
            hintStyle: GoogleFonts.sansita(
                color: _primaryDeep.withValues(alpha: 0.35), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: _primaryDeep.withValues(alpha: 0.45), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: _primaryDeep.withValues(alpha: 0.4), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _filtrar();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── FILTROS POR ROL ───────────────────────────────────────────────────────
  Widget _buildFiltrosRol() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final rol = _roles[i];
          final isActive = _filtroRol == rol;
          return GestureDetector(
            onTap: () => _aplicarFiltroRol(rol),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? _primaryDeep
                    : _primaryDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rol == 'Todos' ? 'Todos' : _getRolLabel(rol),
                style: GoogleFonts.sansita(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : _primaryDeep.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryDeep));
    }

    if (_usuarios.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_off_rounded,
              size: 64, color: _primaryDeep.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text('No hay usuarios registrados',
              style: GoogleFonts.sansita(
                  fontSize: 16, color: _primaryDeep.withValues(alpha: 0.4))),
        ]),
      );
    }

    if (_usuariosFiltrados.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: _primaryDeep.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Sin resultados',
              style: GoogleFonts.sansita(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryDeep.withValues(alpha: 0.35))),
          const SizedBox(height: 4),
          Text('Intenta con otro nombre o filtro',
              style: GoogleFonts.sansita(
                  fontSize: 13, color: _primaryDeep.withValues(alpha: 0.3))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      itemCount: _usuariosFiltrados.length,
      itemBuilder: (_, index) {
        final usuario = _usuariosFiltrados[index];
        final rolColor = _getRolColor(usuario['rol']);
        final rolInfo = _getRolInfo(usuario['rol'] ?? 'jugador');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                  color: _primaryDeep.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(children: [
            // Avatar con inicial
            CircleAvatar(
              radius: 24,
              backgroundColor: rolColor.withValues(alpha: 0.12),
              child: Text(
                (usuario['nombre'] ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.sansita(
                    fontSize: 18, fontWeight: FontWeight.bold, color: rolColor),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(usuario['nombre'] ?? 'Sin nombre',
                      style: GoogleFonts.sansita(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primaryDeep),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(usuario['email'] ?? '',
                      style: GoogleFonts.sansita(
                          fontSize: 12,
                          color: _primaryDeep.withValues(alpha: 0.45)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Badge rol
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: rolColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: rolColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(rolInfo['icon'] as IconData,
                          size: 11, color: rolColor),
                      const SizedBox(width: 4),
                      Text(_getRolLabel(usuario['rol']),
                          style: GoogleFonts.sansita(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: rolColor)),
                    ]),
                  ),
                ])),
            // Botón editar
            Material(
              color: _primaryDeep.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _mostrarBottomSheetRol(usuario),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child:
                      Icon(Icons.edit_rounded, color: _primaryDeep, size: 18),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
