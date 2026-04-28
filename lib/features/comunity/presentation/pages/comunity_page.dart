import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutterapp/config.dart';
import 'package:flutterapp/features/comunity/presentation/pages/player_detail_page.dart';
import 'package:flutterapp/core/routes/routes.dart';

class Groups extends StatefulWidget {
  const Groups({super.key});

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryDeep = const Color(0xFF19382F);

  final Color gris = Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPremiumHeader(),
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PlayersTab(),
                const GroupsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: gris,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila 1: Notificaciones ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: _primaryDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Fila 2: Icono + Título ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primaryDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      size: 24,
                      color: _primaryDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Comunidad',
                    style: GoogleFonts.sansita(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Fila 3: Descripción ──
              Text(
                'Conecta con otros jugadores',
                style: GoogleFonts.sansita(
                  fontSize: 16,
                  color: _primaryDeep.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: _primaryDeep,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle:
              GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Jugadores"),
            Tab(text: "Grupos"),
          ],
        ),
      ),
    );
  }
}

class PlayersTab extends StatefulWidget {
  const PlayersTab({super.key});

  @override
  _PlayersTabState createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final Color _primaryDeep = const Color(0xFF19382F);
  List<dynamic> _players = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String? _userRol;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchPlayers();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRol = prefs.getString('userRol');
    });
  }

  Future<void> _fetchPlayers() async {
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/api/jugadores'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() { _players = data; _filtered = data; _isLoading = false; });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = _players;
      } else {
        _filtered = _players.where((p) {
          final nombre = '${p['usuario']?['nombre'] ?? ''} ${p['usuario']?['apellidos'] ?? ''}'.toLowerCase();
          final pos = (p['posicion'] ?? '').toLowerCase();
          return nombre.contains(q.toLowerCase()) || pos.contains(q.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deletePlayer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar jugador', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que quieres eliminar este jugador?', style: GoogleFonts.sansita()),
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
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final res = await http.delete(
      Uri.parse('${Config.baseUrl}/api/jugadores/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      _fetchPlayers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  int _overall(Map<String, dynamic> p) {
    final pos = p['posicion'];
    final keys = pos == 'Portero'
        ? ['Reflejos', 'Saque', 'Manejo', 'Estirada', 'Velocidad', 'Posicionamiento']
        : ['Ritmo', 'Tiro', 'Pase', 'Regate', 'Defensa', 'Físico'];
    final attrs = p['atributos'] as Map<String, dynamic>? ?? {};
    int sum = 0, count = 0;
    for (var k in keys) {
      if (attrs[k] != null) { sum += (attrs[k] as num).toInt(); count++; }
    }
    return count > 0 ? (sum / count).round() : 50;
  }

  String _posAbr(String? pos) {
    switch (pos) {
      case 'Portero': return 'POR';
      case 'Defensa': return 'DEF';
      case 'Mediocampista': return 'MED';
      case 'Delantero': return 'DEL';
      default: return '—';
    }
  }

  String _avatarUrl(Map<String, dynamic>? usuario) {
    final av = usuario?['avatar'];
    if (av == null || av.toString().isEmpty) {
      return 'https://w7.pngwing.com/pngs/1008/377/png-transparent-computer-icons-avatar-user-profile-avatar-heroes-black-hair-computer.png';
    }
    return av.toString().startsWith('http') ? av.toString() : '${Config.baseUrl}$av';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
            ),
            child: TextField(
              onChanged: _onSearch,
              style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep),
              decoration: InputDecoration(
                hintText: 'Buscar jugador o posición…',
                hintStyle: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.35), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: _primaryDeep.withValues(alpha: 0.4), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // ── List ──
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryDeep))
              : _filtered.isEmpty
                  ? Center(child: Text('No hay jugadores',
                      style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildPlayerCard(_filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final usuario = player['usuario'] as Map<String, dynamic>?;
    final nombre = '${usuario?['nombre'] ?? ''} ${usuario?['apellidos'] ?? ''}'.trim();
    final pos = player['posicion'] as String?;
    final ov = _overall(player);
    final nacionalidadStr = usuario?['nacionalidad'];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PlayerDetailPage(jugador: player))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
          boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.06),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryDeep.withValues(alpha: 0.12), width: 2),
                image: DecorationImage(image: NetworkImage(_avatarUrl(usuario)), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre.isEmpty ? 'Jugador' : nombre,
                    style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(_posAbr(pos),
                        style: GoogleFonts.sansita(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryDeep)),
                  ),
                  const SizedBox(width: 6),
                  Text('${player['edad'] ?? '-'} años',
                      style: GoogleFonts.sansita(fontSize: 11, color: _primaryDeep.withValues(alpha: 0.45))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 12, color: _primaryDeep.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(nacionalidadStr?.toString().isNotEmpty == true ? nacionalidadStr : 'N/A',
                        style: GoogleFonts.sansita(fontSize: 11, color: _primaryDeep.withValues(alpha: 0.5)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 12),

            // Overall badge
            Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE5C07B), Color(0xFFC49A45)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFFC49A45).withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$ov', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900,
                      color: Colors.black87, height: 1)),
                  Text(_posAbr(pos), style: GoogleFonts.sansita(fontSize: 9,
                      fontWeight: FontWeight.bold, color: Colors.black54)),
                ]),
              ),
              const SizedBox(height: 6),
              Icon(Icons.chevron_right_rounded, color: _primaryDeep.withValues(alpha: 0.3), size: 18),
            ]),
            if (_userRol == 'superadmin')
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: () => _deletePlayer(player['_id']),
              ),
          ]),
        ),
      ),
    );
  }
}

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  _GroupsTabState createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final Color _primaryDeep = const Color(0xFF19382F);

  Future<List<dynamic>> fetchGroups() async {
    final response = await http.get(Uri.parse('${Config.baseUrl}/api/grupos'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar grupos');
    }
  }

  String? _userRol;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRol = prefs.getString('userRol');
    });
  }

  Future<void> _deleteGroup(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar grupo', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que quieres eliminar este grupo?', style: GoogleFonts.sansita()),
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
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final res = await http.delete(
      Uri.parse('${Config.baseUrl}/api/grupo/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<dynamic>>(
        future: fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryDeep));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar grupos", style: GoogleFonts.sansita()));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text("No hay grupos disponibles",
                    style: GoogleFonts.sansita(color: _primaryDeep.withValues(alpha: 0.4))));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var group = snapshot.data![index];
              return _buildGroupCard(group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/newGroup');
          if (result == true) setState(() {});
        },
        backgroundColor: _primaryDeep,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Crear Grupo', style: GoogleFonts.sansita(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final String? foto = group['foto'];
    final String fotoUrl = (foto != null && foto.isNotEmpty)
        ? (foto.startsWith('http') ? foto : '${Config.baseUrl}$foto')
        : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=200&auto=format&fit=crop';

    final String adminName = group['admin'] != null
        ? '${group['admin']['nombre'] ?? ''} ${group['admin']['apellidos'] ?? ''}'.trim()
        : 'Admin';

    final bool isPublic = group['privacidad'] != 'privado';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: _primaryDeep.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.pushNamed(context, Routes.groupDetail, arguments: group);
              if (result == true) {
                // Forzar refresco de la lista si se eliminó o editó algo
                setState(() {}); 
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de cabecera del grupo
                Stack(
                  children: [
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: Image.network(fotoUrl, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(isPublic ? Icons.public_rounded : Icons.lock_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              isPublic ? 'Público' : 'Privado',
                              style: GoogleFonts.sansita(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group['nombre'] ?? "Grupo",
                              style: GoogleFonts.sansita(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _primaryDeep,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_userRol == 'superadmin')
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteGroup(group['_id']),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['descripcion'] ?? "Sin descripción",
                        style: GoogleFonts.sansita(
                          fontSize: 13,
                          color: _primaryDeep.withValues(alpha: 0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Stack de avatares de integrantes (mini)
                          SizedBox(
                            width: 60,
                            height: 24,
                            child: Stack(
                              children: List.generate(
                                (group['integrantes']?.length ?? 0) > 3 ? 3 : (group['integrantes']?.length ?? 0),
                                (i) => Positioned(
                                  left: i * 15.0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      color: _primaryDeep.withValues(alpha: 0.1),
                                      image: group['integrantes'][i]['avatar'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(group['integrantes'][i]['avatar'].startsWith('http')
                                                  ? group['integrantes'][i]['avatar']
                                                  : '${Config.baseUrl}${group['integrantes'][i]['avatar']}'),
                                              fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: group['integrantes'][i]['avatar'] == null
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "+${group['integrantes']?.length ?? 0} miembros",
                            style: GoogleFonts.sansita(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _primaryDeep.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "por $adminName",
                            style: GoogleFonts.sansita(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: _primaryDeep.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
