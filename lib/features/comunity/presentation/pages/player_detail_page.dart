import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class PlayerDetailPage extends StatefulWidget {
  final Map<String, dynamic> jugador;
  const PlayerDetailPage({super.key, required this.jugador});

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage>
    with SingleTickerProviderStateMixin {
  final Color _primaryDeep = const Color(0xFF19382F);
  final Color _gold = const Color(0xFFE5C07B);
  final Color _goldDark = const Color(0xFFC49A45);

  String? _myUserId;
  String? _myToken;
  int? _myRating; // rating que YO le di (1-5 estrellas)
  late AnimationController _cardAnim;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardScale = CurvedAnimation(parent: _cardAnim, curve: Curves.elasticOut);
    _loadSession();
    _cardAnim.forward();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myUserId = prefs.getString('userId');
      _myToken = prefs.getString('userToken');
    });
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  Map<String, dynamic> get _usuario =>
      (widget.jugador['usuario'] is Map) ? widget.jugador['usuario'] : {};

  String get _nombre =>
      '${_usuario['nombre'] ?? ''} ${_usuario['apellidos'] ?? ''}'.trim();

  String get _avatarUrl {
    final av = _usuario['avatar'];
    if (av == null || av.toString().isEmpty) {
      return 'https://w7.pngwing.com/pngs/1008/377/png-transparent-computer-icons-avatar-user-profile-avatar-heroes-black-hair-computer.png';
    }
    return av.toString().startsWith('http')
        ? av.toString()
        : '${Config.baseUrl}$av';
  }

  List<String> get _attrKeys {
    final pos = widget.jugador['posicion'];
    return pos == 'Portero'
        ? [
            'Reflejos',
            'Saque',
            'Manejo',
            'Estirada',
            'Velocidad',
            'Posicionamiento'
          ]
        : ['Ritmo', 'Tiro', 'Pase', 'Regate', 'Defensa', 'Físico'];
  }

  int get _overall {
    final attrs = widget.jugador['atributos'] as Map<String, dynamic>? ?? {};
    if (attrs.isEmpty) return 50;
    int sum = 0, count = 0;
    for (var k in _attrKeys) {
      if (attrs[k] != null) {
        sum += (attrs[k] as num).toInt();
        count++;
      }
    }
    return count > 0 ? (sum / count).round() : 50;
  }

  String get _posAbr {
    switch (widget.jugador['posicion']) {
      case 'Portero':
        return 'POR';
      case 'Defensa':
        return 'DEF';
      case 'Mediocampista':
        return 'MED';
      case 'Delantero':
        return 'DEL';
      default:
        return '-';
    }
  }

  Color _attrColor(int v) {
    if (v >= 80) return Colors.green.shade500;
    if (v >= 60) return const Color(0xFFF59E0B);
    return Colors.red.shade400;
  }

  // ── Fetch & actions ───────────────────────────────────────────────────────
  Future<List<dynamic>> _fetchMyGroups() async {
    if (_myUserId == null) return [];
    final res = await http.get(
      Uri.parse('${Config.baseUrl}/api/grupos/usuario/$_myUserId'),
      headers: {if (_myToken != null) 'Authorization': 'Bearer $_myToken'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  Future<List<dynamic>> _fetchMyReservas() async {
    if (_myUserId == null) return [];
    final res = await http.get(
      Uri.parse('${Config.baseUrl}/api/reservas/$_myUserId'),
      headers: {if (_myToken != null) 'Authorization': 'Bearer $_myToken'},
    );
    if (res.statusCode == 200) return json.decode(res.body);
    return [];
  }

  Future<void> _sendInvite({String? reservaId, String? desafio}) async {
    final targetUserId = _usuario['_id']?.toString();
    if (_myUserId == null || targetUserId == null) return;
    final body = {
      'tipo': 'jugador',
      'invitanteId': _myUserId,
      'invitadoId': targetUserId,
      if (reservaId != null) 'reservaId': reservaId,
      if (desafio != null) 'desafio': desafio,
    };
    final res = await http.post(
      Uri.parse('${Config.baseUrl}/api/invitacion'),
      headers: {
        'Content-Type': 'application/json',
        if (_myToken != null) 'Authorization': 'Bearer $_myToken',
      },
      body: json.encode(body),
    );
    if (mounted) {
      Navigator.pop(context);
      _showSnack(
        res.statusCode == 201
            ? '¡Invitación enviada a $_nombre!'
            : 'Error al enviar invitación',
        isError: res.statusCode != 201,
      );
    }
  }

  Future<void> _enviarValoracion(int rating) async {
    final targetUserId = _usuario['_id']?.toString();
    if (_myUserId == null || targetUserId == null) return;
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/api/jugadores/valorar'),
        headers: {
          'Content-Type': 'application/json',
          if (_myToken != null) 'Authorization': 'Bearer $_myToken',
        },
        body: json.encode({
          'jugadorId': widget.jugador['_id'],
          'valoradorId': _myUserId,
          'rating': rating,
        }),
      );
      if (mounted) {
        Navigator.pop(context);
        if (res.statusCode == 200 || res.statusCode == 201) {
          setState(() => _myRating = rating);
          _showSnack('¡Valoración enviada! ⭐ $rating/5');
        } else {
          _showSnack('Error al enviar valoración', isError: true);
        }
      }
    } catch (_) {
      if (mounted) _showSnack('Error de conexión', isError: true);
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

  // ── Bottom sheets ─────────────────────────────────────────────────────────
  void _showRatingSheet() {
    int tempRating = _myRating ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                  child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4)),
              )),
              const SizedBox(height: 24),

              // Avatar jugador
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 3),
                  image: DecorationImage(
                      image: NetworkImage(_avatarUrl), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Text('Valorar a $_nombre',
                  style: GoogleFonts.sansita(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('¿Cómo calificarías a este jugador?',
                  style: GoogleFonts.sansita(
                      fontSize: 13,
                      color: _primaryDeep.withValues(alpha: 0.45))),
              const SizedBox(height: 28),

              // Estrellas grandes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < tempRating;
                  return GestureDetector(
                    onTap: () => setSheet(() => tempRating = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 48,
                        color: filled
                            ? Colors.orange.shade400
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                tempRating == 0
                    ? 'Toca una estrella'
                    : tempRating == 1
                        ? '⚽ Principiante'
                        : tempRating == 2
                            ? '🥉 Regular'
                            : tempRating == 3
                                ? '🥈 Bueno'
                                : tempRating == 4
                                    ? '🥇 Muy bueno'
                                    : '🏆 Elite',
                style: GoogleFonts.sansita(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tempRating == 0
                        ? _primaryDeep.withValues(alpha: 0.3)
                        : Colors.orange.shade600),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: tempRating == 0
                      ? null
                      : () => _enviarValoracion(tempRating),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDeep,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _primaryDeep.withValues(alpha: 0.25),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Enviar valoración',
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

  void _showInviteToTeam() async {
    final grupos = await _fetchMyGroups();
    if (!mounted) return;
    _showListSheet(
      title: 'Invitar a mi equipo',
      subtitle: 'Selecciona el equipo para $_nombre',
      emptyMsg: 'No tienes equipos creados aún.',
      items: grupos,
      color: _primaryDeep,
      icon: Icons.group_rounded,
      labelBuilder: (g) => g['nombre'] ?? 'Equipo',
      subtitleBuilder: (g) =>
          '${(g['integrantes'] as List?)?.length ?? 0} integrantes',
      onTap: (g) =>
          _sendInvite(desafio: 'Invitación al equipo: ${g['nombre']}'),
    );
  }

  void _showInviteToMatch() async {
    final reservas = await _fetchMyReservas();
    if (!mounted) return;
    _showListSheet(
      title: 'Invitar a un partido',
      subtitle: 'Selecciona el partido para $_nombre',
      emptyMsg: 'No tienes partidos reservados aún.',
      items: reservas,
      color: _goldDark,
      icon: Icons.sports_soccer_rounded,
      labelBuilder: (r) => '${r['fecha'] ?? '—'} · ${r['hora'] ?? '—'}',
      subtitleBuilder: (r) => r['estado'] ?? '',
      onTap: (r) => _sendInvite(reservaId: r['_id']?.toString()),
    );
  }

  void _showListSheet({
    required String title,
    required String subtitle,
    required String emptyMsg,
    required List<dynamic> items,
    required Color color,
    required IconData icon,
    required String Function(dynamic) labelBuilder,
    required String Function(dynamic) subtitleBuilder,
    required Function(dynamic) onTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            )),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.sansita(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryDeep)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.sansita(
                    fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(emptyMsg,
                        style: GoogleFonts.sansita(
                            color: _primaryDeep.withValues(alpha: 0.4)))),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Material(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onTap(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(labelBuilder(item),
                                    style: GoogleFonts.sansita(
                                        fontWeight: FontWeight.w700,
                                        color: _primaryDeep,
                                        fontSize: 14)),
                                Text(subtitleBuilder(item),
                                    style: GoogleFonts.sansita(
                                        fontSize: 12,
                                        color: _primaryDeep.withValues(
                                            alpha: 0.45))),
                              ],
                            )),
                            Icon(Icons.chevron_right_rounded,
                                color: _primaryDeep.withValues(alpha: 0.25)),
                          ]),
                        ),
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final attrs = widget.jugador['atributos'] as Map<String, dynamic>? ?? {};
    final galeria = (widget.jugador['galeria'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F18),
      body: Stack(
        children: [
          // ── Fondo tipo estadio ────────────────────────────────────────
          _buildStadiumBackground(),

          CustomScrollView(
            slivers: [
              // ── HERO SECTION ──────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeroSection()),

              // ── CARTA FIFA ANIMADA ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: _buildFifaCard(attrs),
                  ),
                ),
              ),

              // ── CONTENIDO BLANCO ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre grande
                        Text(
                          _nombre.toUpperCase(),
                          style: GoogleFonts.sansita(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _primaryDeep,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          _buildPillBadge(
                              widget.jugador['posicion'] ?? '-', _primaryDeep),
                          const SizedBox(width: 8),
                          _buildPillBadge(
                              '${widget.jugador['edad'] ?? '-'} años',
                              Colors.grey.shade600),
                          const SizedBox(width: 8),
                          _buildPillBadge(
                              '${widget.jugador['estatura'] ?? '-'} cm',
                              Colors.grey.shade600),
                        ]),
                        const SizedBox(height: 28),

                        // ── Stats hexagonales / grid ──────────────────
                        _buildSectionTitle(
                            Icons.bar_chart_rounded, 'Atributos'),
                        const SizedBox(height: 14),
                        _buildAttributesGrid(attrs),
                        const SizedBox(height: 28),

                        // ── Info personal ─────────────────────────────
                        _buildSectionTitle(
                            Icons.person_outline_rounded, 'Información'),
                        const SizedBox(height: 14),
                        _buildPersonalInfoRow(),
                        const SizedBox(height: 28),

                        // ── Galería ───────────────────────────────────
                        if (galeria.isNotEmpty) ...[
                          _buildSectionTitle(
                              Icons.photo_library_rounded, 'Galería'),
                          const SizedBox(height: 14),
                          _buildGallery(galeria),
                          const SizedBox(height: 28),
                        ],

                        // ── Botones de acción ─────────────────────────
                        _buildSectionTitle(Icons.flash_on_rounded, 'Acciones'),
                        const SizedBox(height: 14),

                        // Valorar (destacado)
                        _buildGlowButton(
                          icon: Icons.star_rounded,
                          label: _myRating != null
                              ? 'Tu valoración: $_myRating/5 ⭐'
                              : 'Valorar jugador',
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade500,
                              Colors.orange.shade700
                            ],
                          ),
                          onTap: _showRatingSheet,
                        ),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(
                            child: _buildSquareAction(
                              icon: Icons.group_add_rounded,
                              label: 'Invitar al\nequipo',
                              color: _primaryDeep,
                              onTap: _showInviteToTeam,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSquareAction(
                              icon: Icons.sports_soccer_rounded,
                              label: 'Invitar al\npartido',
                              color: _goldDark,
                              onTap: _showInviteToMatch,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Botón volver flotante
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildStadiumBackground() {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D3D2A),
            const Color(0xFF19382F),
            const Color(0xFF0D1F18),
          ],
        ),
      ),
      child: Stack(children: [
        // Líneas de cancha decorativas
        Center(
          child: CustomPaint(
            size: const Size(double.infinity, 420),
            painter: _FieldLinesPainter(),
          ),
        ),
        // Gradiente encima para suavizar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0D1F18).withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeroSection() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        child: Column(
          children: [
            // Avatar con anillo dorado
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_gold, _goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.network(_avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: _primaryDeep,
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 40))),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _nombre.toUpperCase(),
              style: GoogleFonts.sansita(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Overall badge estilo FIFA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_gold, _goldDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 12)
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$_overall',
                    style: GoogleFonts.sansita(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
                const SizedBox(width: 6),
                Text('OVR',
                    style: GoogleFonts.sansita(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const SizedBox(width: 12),
                Container(
                    width: 1,
                    height: 18,
                    color: Colors.black.withValues(alpha: 0.2)),
                const SizedBox(width: 12),
                Text(_posAbr,
                    style: GoogleFonts.sansita(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFifaCard(Map<String, dynamic> attrs) {
    final keys = _attrKeys;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gold, _goldDark, const Color(0xFFB8892C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _gold.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 8)),
        ],
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Stack(children: [
        // Marca de agua
        Positioned(
          right: -20,
          bottom: -20,
          child: Icon(Icons.sports_soccer,
              size: 160, color: Colors.white.withValues(alpha: 0.07)),
        ),
        Column(children: [
          Row(children: [
            // Avatar en la carta
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
                image: DecorationImage(
                    image: NetworkImage(_avatarUrl), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombre.toUpperCase(),
                    style: GoogleFonts.sansita(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  _buildCardBadge('$_overall', Colors.black87, large: true),
                  const SizedBox(width: 8),
                  _buildCardBadge(_posAbr, Colors.black54),
                  const SizedBox(width: 8),
                  _buildCardBadge(
                      widget.jugador['posicion']
                              ?.toString()
                              .substring(0, 3)
                              .toUpperCase() ??
                          '-',
                      Colors.black38),
                ]),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: Colors.black.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          // Stats en 2 columnas
          Row(
            children: [
              Expanded(
                  child: Column(
                children: keys
                    .sublist(0, 3)
                    .map((k) =>
                        _buildCardStatRow(k, (attrs[k] as num?)?.toInt() ?? 50))
                    .toList(),
              )),
              Container(
                  width: 1,
                  height: 80,
                  color: Colors.black.withValues(alpha: 0.1)),
              Expanded(
                  child: Column(
                children: keys
                    .sublist(3)
                    .map((k) =>
                        _buildCardStatRow(k, (attrs[k] as num?)?.toInt() ?? 50))
                    .toList(),
              )),
            ],
          ),
        ]),
      ]),
    );
  }

  Widget _buildCardBadge(String text, Color color, {bool large = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.sansita(
              fontSize: large ? 20 : 12,
              fontWeight: FontWeight.w900,
              color: color)),
    );
  }

  Widget _buildCardStatRow(String label, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(children: [
        Text('$val',
            style: GoogleFonts.sansita(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87)),
        const SizedBox(width: 6),
        Text(
            label.length > 4
                ? label.substring(0, 4).toUpperCase()
                : label.toUpperCase(),
            style: GoogleFonts.sansita(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildAttributesGrid(Map<String, dynamic> attrs) {
    final keys = _attrKeys;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1, // 🔥 más altura para evitar overflow
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final val = (attrs[k] as num?)?.toInt() ?? 50;
        final color = _attrColor(val);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🔥 evita que crezca de más
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$val',
                style: GoogleFonts.sansita(
                  fontSize: 20, // un poco menor para estabilidad
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 2,
                ),
              ),
              const SizedBox(height: 2),

              // Mini barra
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val / 99,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                k,
                style: GoogleFonts.sansita(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _primaryDeep.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoRow() {
    final items = [
      {
        'icon': Icons.public_rounded,
        'label': 'Nación',
        'value': _usuario['nacionalidad']?.toString().isNotEmpty == true
            ? _usuario['nacionalidad']
            : 'N/A'
      },
      {
        'icon': Icons.height_rounded,
        'label': 'Estatura',
        'value': widget.jugador['estatura'] != null
            ? '${widget.jugador['estatura']} cm'
            : 'N/A'
      },
      {
        'icon': Icons.cake_rounded,
        'label': 'Edad',
        'value': widget.jugador['edad'] != null
            ? '${widget.jugador['edad']} años'
            : 'N/A'
      },
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == items.length - 1;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _primaryDeep.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
                ),
                child: Column(children: [
                  Icon(item['icon'] as IconData,
                      size: 20, color: _primaryDeep.withValues(alpha: 0.5)),
                  const SizedBox(height: 6),
                  Text(item['value'] as String,
                      style: GoogleFonts.sansita(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primaryDeep)),
                  Text(item['label'] as String,
                      style: GoogleFonts.sansita(
                          fontSize: 10,
                          color: _primaryDeep.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            if (!isLast) const SizedBox(width: 10),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildGallery(List<dynamic> galeria) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: galeria.length,
      itemBuilder: (_, i) {
        final url = galeria[i].toString().startsWith('http')
            ? galeria[i].toString()
            : '${Config.baseUrl}${galeria[i]}';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: _primaryDeep.withValues(alpha: 0.06),
                  child: Icon(Icons.broken_image_rounded,
                      color: _primaryDeep.withValues(alpha: 0.3)))),
        );
      },
    );
  }

  Widget _buildGlowButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.orange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.sansita(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildSquareAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.sansita(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: GoogleFonts.sansita(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
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
      Text(title,
          style: GoogleFonts.sansita(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _primaryDeep,
              letterSpacing: -0.3)),
    ]);
  }
}

// ── CUSTOM PAINTER: Líneas de cancha ──────────────────────────────────────────
class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Círculo central
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.5), 80, paint);

    // Punto central
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.5), 5, dotPaint);

    // Línea central
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );

    // Arco superior (portería)
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.05),
        width: 180,
        height: 80);
    canvas.drawArc(rect, 0, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
