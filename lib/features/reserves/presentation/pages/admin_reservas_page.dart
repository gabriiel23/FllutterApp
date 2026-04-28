import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class AdminReservasPage extends StatefulWidget {
  const AdminReservasPage({super.key});
  @override
  State<AdminReservasPage> createState() => _AdminReservasPageState();
}

class _AdminReservasPageState extends State<AdminReservasPage> with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF19382F);
  late TabController _tab;
  String? espacioId;
  String? espacioNombre;
  String? _userRol;
  List<dynamic> _espaciosAdmin = [];
  List<Map<String, dynamic>> _todas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 1);
    _init();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userRol = prefs.getString('userRol');
    
    if (_userRol == 'superadmin') {
      await _fetchEspaciosSuperadmin();
    } else {
      espacioId = prefs.getString('espacio_id');
      await _fetch();
    }
  }

  Future<void> _fetchEspaciosSuperadmin() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/api/espacio/espacios-deportivos'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) _espaciosAdmin = decoded;
        else if (decoded is Map && decoded['data'] != null) _espaciosAdmin = decoded['data'];
      }
    } catch (_) {}
    setState(() => _loading = false);
    
    // Auto-show selector on load if no space is selected
    if (espacioId == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSpaceSelector());
    }
  }

  Future<void> _fetch() async {
    if (espacioId == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    try {
      final r = await http.get(Uri.parse('${Config.baseUrl}/api/reservas/espacio/$espacioId'));
      if (r.statusCode == 200) {
        setState(() => _todas = List<Map<String, dynamic>>.from(jsonDecode(r.body)));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showSpaceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          Text('Seleccionar Espacio', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w800, color: _primary)),
          Text('Elige el espacio para ver sus reservas', style: GoogleFonts.sansita(fontSize: 14, color: _primary.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          if (_espaciosAdmin.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No hay espacios disponibles')))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _espaciosAdmin.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final e = _espaciosAdmin[i];
                  final isActive = espacioId == e['_id'];
                  return Material(
                    color: isActive ? _primary.withValues(alpha: 0.08) : _primary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          espacioId = e['_id'];
                          espacioNombre = e['nombre'];
                        });
                        _fetch();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Icon(Icons.stadium_rounded, color: isActive ? _primary : _primary.withValues(alpha: 0.5)),
                          const SizedBox(width: 14),
                          Expanded(child: Text(e['nombre'] ?? 'Espacio', style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: _primary))),
                          if (isActive) Icon(Icons.check_circle_rounded, color: _primary)
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }

  static String _hoy() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }



  List<Map<String, dynamic>> _deHoy() => _todas.where((r) => r['fecha'] == _hoy()).toList()
    ..sort((a, b) => (a['hora'] ?? '').compareTo(b['hora'] ?? ''));

  List<Map<String, dynamic>> _deDia(String fecha) => _todas.where((r) => r['fecha'] == fecha).toList()
    ..sort((a, b) => (a['hora'] ?? '').compareTo(b['hora'] ?? ''));

  Widget _buildBody() {
    if (_userRol == 'superadmin' && espacioId == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_rounded, size: 64, color: _primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Selecciona un espacio', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
          Text('para ver sus reservas', style: GoogleFonts.sansita(fontSize: 14, color: _primary.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showSpaceSelector,
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Seleccionar ahora', style: GoogleFonts.sansita(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      );
    }
    return TabBarView(
      controller: _tab,
      children: [
        _TabNavDias(todas: _todas, deDia: _deDia, tipo: 'pasadas', onRefresh: _fetch),
        _TabHoy(reservas: _deHoy(), loading: _loading, onRefresh: _fetch),
        _TabNavDias(todas: _todas, deDia: _deDia, tipo: 'futuras', onRefresh: _fetch),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primary, const Color(0xFF2D5C48)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(bottom: false, child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reservas', style: GoogleFonts.sansita(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                if (_userRol == 'superadmin' && espacioNombre != null)
                  GestureDetector(
                    onTap: _showSpaceSelector,
                    child: Row(children: [
                      Text(espacioNombre!, style: GoogleFonts.sansita(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ]),
                  ),
              ]),
            ),
            if (_userRol == 'superadmin')
              IconButton(onPressed: _showSpaceSelector, icon: const Icon(Icons.filter_list_rounded, color: Colors.white)),
            IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.sansita(fontSize: 13),
          tabs: const [
            Tab(text: 'Pasadas'),
            Tab(text: 'Hoy'),
            Tab(text: 'Próximas'),
          ],
        ),
      ])),
    );
  }
}

// ── Tab de Hoy ───────────────────────────────────────────────────────────────
class _TabHoy extends StatelessWidget {
  final List<Map<String, dynamic>> reservas;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _TabHoy({required this.reservas, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)));
    if (reservas.isEmpty) return _empty('No hay reservas para hoy');
    return RefreshIndicator(
      onRefresh: onRefresh, color: const Color(0xFF19382F),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reservas.length,
        itemBuilder: (_, i) => _ReservaCard(reserva: reservas[i], onChanged: onRefresh),
      ),
    );
  }
}

// ── Tab navegable (Pasadas / Futuras) ────────────────────────────────────────
class _TabNavDias extends StatefulWidget {
  final List<Map<String, dynamic>> todas;
  final List<Map<String, dynamic>> Function(String) deDia;
  final String tipo; // 'pasadas' | 'futuras'
  final Future<void> Function() onRefresh;
  const _TabNavDias({required this.todas, required this.deDia, required this.tipo, required this.onRefresh});

  @override
  State<_TabNavDias> createState() => _TabNavDiasState();
}

class _TabNavDiasState extends State<_TabNavDias> {
  late DateTime _sel;
  static const _primary = Color(0xFF19382F);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _sel = widget.tipo == 'pasadas'
        ? now.subtract(const Duration(days: 1))
        : now.add(const Duration(days: 1));
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  List<DateTime> get _dias {
    final now = DateTime.now();
    if (widget.tipo == 'pasadas') {
      return List.generate(7, (i) => now.subtract(Duration(days: 7 - i)));
    } else {
      return List.generate(7, (i) => now.add(Duration(days: i + 1)));
    }
  }

  bool _tieneReservas(DateTime d) => widget.todas.any((r) => r['fecha'] == _dateStr(d));

  @override
  Widget build(BuildContext context) {
    final reservasDia = widget.deDia(_dateStr(_sel));
    final diasL = ['L','M','X','J','V','S','D'];

    return Column(children: [
      // Barra de días
      Container(
        height: 86,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _dias.length,
          itemBuilder: (_, i) {
            final d = _dias[i];
            final sel = _dateStr(d) == _dateStr(_sel);
            final tiene = _tieneReservas(d);
            return GestureDetector(
              onTap: () => setState(() => _sel = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: sel ? _primary : _primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.1)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(diasL[d.weekday - 1], style: GoogleFonts.sansita(fontSize: 11, color: sel ? Colors.white60 : _primary.withValues(alpha: 0.5))),
                  Text('${d.day}', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w900, color: sel ? Colors.white : _primary)),
                  if (tiene)
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: sel ? Colors.white : _primary, shape: BoxShape.circle)),
                ]),
              ),
            );
          },
        ),
      ),
      Divider(height: 1, color: _primary.withValues(alpha: 0.07)),
      // Lista
      Expanded(child: reservasDia.isEmpty
          ? _empty(widget.tipo == 'pasadas' ? 'Sin reservas ese día' : 'Sin reservas futuras ese día')
          : RefreshIndicator(
              onRefresh: widget.onRefresh, color: _primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: reservasDia.length,
                itemBuilder: (_, i) => _ReservaCard(reserva: reservasDia[i], onChanged: widget.onRefresh),
              ),
            )),
    ]);
  }
}

// ── Card de reserva ──────────────────────────────────────────────────────────
class _ReservaCard extends StatelessWidget {
  final Map<String, dynamic> reserva;
  final Future<void> Function() onChanged;
  const _ReservaCard({required this.reserva, required this.onChanged});

  static const _primary = Color(0xFF19382F);

  Color get _statusColor {
    switch (reserva['estado']) {
      case 'Confirmada': return Colors.green.shade600;
      case 'EsperandoValidacion': return Colors.orange.shade700;
      case 'Cancelada': return Colors.red.shade500;
      case 'Terminada': return Colors.grey;
      default: return Colors.blue.shade600;
    }
  }

  String get _estadoLabel {
    switch (reserva['estado']) {
      case 'EsperandoValidacion': return 'Validando';
      default: return reserva['estado'] ?? 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DetalleReservaAdminPage(reserva: reserva),
      )).then((_) => onChanged()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _primary.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Hora
          Container(
            width: 64, padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_time_rounded, size: 13, color: _primary.withValues(alpha: 0.4)),
              const SizedBox(height: 3),
              Text(reserva['hora'] ?? '', style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.w900, color: _primary), textAlign: TextAlign.center),
            ]),
          ),
          // Info
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reserva['servicio']?['nombre'] ?? 'Servicio',
                  style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.w800, color: _primary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 12, color: _primary.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Expanded(child: Text(
                  reserva['nombreCliente'] ?? reserva['usuario']?['nombre'] ?? '—',
                  style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ]),
          )),
          // Estado
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_estadoLabel, style: GoogleFonts.sansita(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor)),
              ),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right_rounded, color: _primary.withValues(alpha: 0.25), size: 18),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Detalle de Reserva ────────────────────────────────────────────────────────
class DetalleReservaAdminPage extends StatefulWidget {
  final Map<String, dynamic> reserva;
  const DetalleReservaAdminPage({super.key, required this.reserva});
  @override
  State<DetalleReservaAdminPage> createState() => _DetalleReservaAdminPageState();
}

class _DetalleReservaAdminPageState extends State<DetalleReservaAdminPage> {
  static const _primary = Color(0xFF19382F);
  late Map<String, dynamic> _r;
  bool _guardando = false;

  @override
  void initState() { super.initState(); _r = Map<String, dynamic>.from(widget.reserva); }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
      backgroundColor: error ? Colors.red.shade600 : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _cambiarEstado(String estado) async {
    setState(() => _guardando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.patch(
        Uri.parse('${Config.baseUrl}/api/reservas/${_r['_id']}/estado'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'estado': estado}),
      );
      if (resp.statusCode == 200) {
        setState(() => _r['estado'] = estado);
        _snack(estado == 'Confirmada' ? '✅ Pago confirmado' : '❌ Pago rechazado', error: estado == 'Cancelada');
      } else {
        _snack('Error al actualizar', error: true);
      }
    } catch (_) { _snack('Error de conexión', error: true); }
    setState(() => _guardando = false);
  }

  Color _statusColor(String e) {
    switch (e) {
      case 'Confirmada': return Colors.green.shade600;
      case 'EsperandoValidacion': return Colors.orange.shade700;
      case 'Cancelada': return Colors.red.shade500;
      case 'Terminada': return Colors.grey.shade500;
      default: return Colors.blue.shade600;
    }
  }

  String _estadoLabel(String e) {
    switch (e) {
      case 'EsperandoValidacion': return 'Esperando validación de pago';
      case 'Confirmada': return 'Confirmada';
      case 'Cancelada': return 'Cancelada';
      case 'Terminada': return 'Terminada';
      default: return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _r['estado'] ?? 'Pendiente';
    final comprobante = _r['comprobanteUrl'];
    final esPresencial = _r['creadoPorAdmin'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Detalle de Reserva', style: GoogleFonts.sansita(color: _primary, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white, elevation: 0, foregroundColor: _primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Estado badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _statusColor(estado).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _statusColor(estado).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(_statusIcon(estado), color: _statusColor(estado), size: 26),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_estadoLabel(estado), style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w900, color: _statusColor(estado))),
                if (esPresencial) Text('Reserva presencial (admin)', style: GoogleFonts.sansita(fontSize: 12, color: _statusColor(estado).withValues(alpha: 0.6))),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Info principal
          _infoCard(),
          const SizedBox(height: 20),

          // Comprobante de pago
          if (comprobante != null && comprobante.toString().isNotEmpty) ...[
            _sectionTitle(Icons.receipt_long_rounded, 'Comprobante de pago'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showComprobanteFullscreen(comprobante),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  comprobante,
                  width: double.infinity, height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Toca la imagen para verla en pantalla completa', style: GoogleFonts.sansita(fontSize: 11, color: _primary.withValues(alpha: 0.4))),
            const SizedBox(height: 20),
          ],

          // Acciones de validación
          if (estado == 'EsperandoValidacion') ...[
            _sectionTitle(Icons.verified_rounded, 'Validar pago'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Revisa el comprobante y confirma o rechaza el pago.', style: GoogleFonts.sansita(fontSize: 13, color: Colors.orange.shade800))),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _guardando ? null : () => _confirmarAccion('Cancelada'),
                    icon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade600),
                    label: Text('Rechazar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _guardando ? null : () => _confirmarAccion('Confirmada'),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: _guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirmar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Cancelar si aplica
          if (estado == 'Pendiente' || estado == 'Confirmada') ...[
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: _guardando ? null : () => _confirmarAccion('Cancelada'),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade300), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('Cancelar reserva', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
            )),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  void _confirmarAccion(String estado) {
    final label = estado == 'Confirmada' ? '¿Confirmar el pago de esta reserva?' : '¿Cancelar / rechazar esta reserva?';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(estado == 'Confirmada' ? 'Confirmar pago' : 'Cancelar reserva', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
        content: Text(label, style: GoogleFonts.sansita()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Atrás', style: GoogleFonts.sansita())),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _cambiarEstado(estado); },
            style: ElevatedButton.styleFrom(backgroundColor: estado == 'Confirmada' ? Colors.green.shade600 : Colors.red, foregroundColor: Colors.white),
            child: Text(estado == 'Confirmada' ? 'Confirmar' : 'Cancelar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final cliente = _r['nombreCliente'] ?? _r['usuario']?['nombre'] ?? '—';
    final metodo = _r['metodoPago'] ?? '—';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _primary.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        _row(Icons.person_rounded, 'Cliente', cliente),
        _div(), _row(Icons.sports_rounded, 'Servicio', _r['servicio']?['nombre'] ?? '—'),
        _div(), _row(Icons.calendar_today_rounded, 'Fecha', _r['fecha'] ?? '—'),
        _div(), _row(Icons.access_time_rounded, 'Hora', _r['hora'] ?? '—'),
        _div(), _row(Icons.payments_rounded, 'Pago', metodo),
        _div(), _row(Icons.tag_rounded, 'Código', _r['codigoReserva'] ?? '—'),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Icon(icon, size: 16, color: _primary.withValues(alpha: 0.4)),
      const SizedBox(width: 10),
      Text('$label:', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.5))),
      const Spacer(),
      Flexible(child: Text(value, style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: _primary), textAlign: TextAlign.end)),
    ]),
  );

  Widget _div() => Divider(height: 1, color: _primary.withValues(alpha: 0.06));

  Widget _sectionTitle(IconData icon, String title) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: _primary)),
    const SizedBox(width: 10),
    Text(title, style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800, color: _primary)),
  ]);

  IconData _statusIcon(String e) {
    switch (e) {
      case 'Confirmada': return Icons.check_circle_rounded;
      case 'EsperandoValidacion': return Icons.hourglass_top_rounded;
      case 'Cancelada': return Icons.cancel_rounded;
      case 'Terminada': return Icons.flag_rounded;
      default: return Icons.pending_rounded;
    }
  }

  void _showComprobanteFullscreen(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
          Positioned(top: 40, right: 16, child: IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          )),
        ]),
      ),
    );
  }
}

Widget _empty(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
  Icon(Icons.event_busy_rounded, size: 64, color: const Color(0xFF19382F).withValues(alpha: 0.12)),
  const SizedBox(height: 14),
  Text(msg, style: GoogleFonts.sansita(fontSize: 16, color: const Color(0xFF19382F).withValues(alpha: 0.35))),
]));
