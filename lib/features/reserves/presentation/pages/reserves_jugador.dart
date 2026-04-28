import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class Reserves_user extends StatefulWidget {
  const Reserves_user({super.key});

  @override
  _ReservesState createState() => _ReservesState();
}

class _ReservesState extends State<Reserves_user> {
  final Color _primaryDeep = const Color(0xFF19382F);
  String? userId;
  List<ReservaModel> reservas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUserId();
  }

  Future<void> _cargarUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
    if (userId != null) await _fetchReservas();
  }

  Future<void> _fetchReservas() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/api/reservas/$userId'));
      if (res.statusCode == 200) {
        final data = List<dynamic>.from(jsonDecode(res.body));
        setState(() => reservas = data.map((j) => ReservaModel.fromJson(j)).toList());
      } else {
        setState(() => reservas = []);
      }
    } catch (_) {
      setState(() => reservas = []);
    }
    setState(() => isLoading = false);
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
        gradient: LinearGradient(
          colors: [_primaryDeep, const Color(0xFF2D5C48)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Mis Reservas', style: GoogleFonts.sansita(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
              IconButton(
                onPressed: _fetchReservas,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Tus partidos programados', style: GoogleFonts.sansita(fontSize: 14, color: Colors.white.withValues(alpha: 0.65))),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return Center(child: CircularProgressIndicator(color: _primaryDeep));
    if (reservas.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy_rounded, size: 72, color: _primaryDeep.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Text('No tienes reservas aún', style: GoogleFonts.sansita(fontSize: 18, color: _primaryDeep.withValues(alpha: 0.4))),
        const SizedBox(height: 8),
        Text('Ve a un espacio deportivo y reserva', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _fetchReservas,
      color: _primaryDeep,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reservas.length,
        itemBuilder: (_, i) => _buildReservaCard(reservas[i]),
      ),
    );
  }

  Widget _buildReservaCard(ReservaModel r) {
    final statusColor = _statusColor(r.estado);
    return GestureDetector(
      onTap: () => _showDetalleSheet(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
                child: Icon(_statusIcon(r.estado), color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.espacio, style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryDeep), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(r.servicio, style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_estadoLabel(r.estado), style: GoogleFonts.sansita(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ]),
          ),
          Divider(height: 1, color: _primaryDeep.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: _primaryDeep.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(r.fecha, style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
              const SizedBox(width: 14),
              Icon(Icons.access_time_rounded, size: 14, color: _primaryDeep.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(r.hora, style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
              const Spacer(),
              Text('Ver detalle →', style: GoogleFonts.sansita(fontSize: 12, color: _primaryDeep, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showDetalleSheet(ReservaModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),

              // Estado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statusColor(r.estado).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _statusColor(r.estado).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(_statusIcon(r.estado), color: _statusColor(r.estado), size: 28),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_estadoLabel(r.estado), style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w900, color: _statusColor(r.estado))),
                    Text(_estadoDescripcion(r.estado), style: GoogleFonts.sansita(fontSize: 12, color: _statusColor(r.estado).withValues(alpha: 0.7))),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              // Info principal
              _infoCard(r),
              const SizedBox(height: 20),

              // QR y código - solo si confirmada
              if (r.estado == 'Confirmada') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: _primaryDeep, borderRadius: BorderRadius.circular(22)),
                  child: Column(children: [
                    Text('Tu pase de entrada', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(data: r.codigoReserva, version: QrVersions.auto, size: 160),
                    ),
                    const SizedBox(height: 16),
                    Text(r.codigoReserva, style: GoogleFonts.sansita(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6)),
                    const SizedBox(height: 4),
                    Text('Muestra este código el día de tu reserva', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // Código solo (estados no confirmados)
              if (r.estado != 'Confirmada' && r.codigoReserva.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: _primaryDeep.withValues(alpha: 0.1))),
                  child: Column(children: [
                    Text('Código de reserva', style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    Text(r.codigoReserva, style: GoogleFonts.sansita(fontSize: 26, fontWeight: FontWeight.w900, color: _primaryDeep, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text('Disponible una vez que se confirme el pago', style: GoogleFonts.sansita(fontSize: 11, color: _primaryDeep.withValues(alpha: 0.4))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // Cancelar si aplica
              if (r.estado == 'Pendiente' || r.estado == 'EsperandoValidacion') ...[
                SizedBox(width: double.infinity, child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _cambiarEstado(r.id, 'Cancelada');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Cancelar reserva', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 16)),
                )),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(ReservaModel r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _infoRow(Icons.business_rounded, 'Espacio', r.espacio),
        _divRow(),
        _infoRow(Icons.sports_rounded, 'Servicio', r.servicio),
        _divRow(),
        _infoRow(Icons.person_rounded, 'Titular', r.usuario),
        _divRow(),
        _infoRow(Icons.calendar_today_rounded, 'Fecha', r.fecha),
        _divRow(),
        _infoRow(Icons.access_time_rounded, 'Horario', r.hora),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: _primaryDeep.withValues(alpha: 0.4)),
        const SizedBox(width: 12),
        Text('$label: ', style: GoogleFonts.sansita(fontSize: 14, color: _primaryDeep.withValues(alpha: 0.5))),
        Expanded(child: Text(value, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryDeep), textAlign: TextAlign.end)),
      ]),
    );
  }

  Widget _divRow() => Divider(height: 1, color: _primaryDeep.withValues(alpha: 0.06));

  Future<void> _cambiarEstado(String id, String estado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      await http.patch(
        Uri.parse('${Config.baseUrl}/api/reservas/$id/estado'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'estado': estado}),
      );
      await _fetchReservas();
    } catch (_) {}
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'Confirmada': return Colors.green.shade600;
      case 'EsperandoValidacion': return Colors.orange.shade600;
      case 'Cancelada': return Colors.red.shade500;
      case 'Terminada': return Colors.grey.shade500;
      default: return Colors.blue.shade600;
    }
  }

  IconData _statusIcon(String estado) {
    switch (estado) {
      case 'Confirmada': return Icons.check_circle_rounded;
      case 'EsperandoValidacion': return Icons.hourglass_top_rounded;
      case 'Cancelada': return Icons.cancel_rounded;
      case 'Terminada': return Icons.flag_rounded;
      default: return Icons.pending_rounded;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'EsperandoValidacion': return 'En validación';
      case 'Confirmada': return 'Confirmada';
      case 'Cancelada': return 'Cancelada';
      case 'Terminada': return 'Terminada';
      default: return 'Pendiente';
    }
  }

  String _estadoDescripcion(String estado) {
    switch (estado) {
      case 'EsperandoValidacion': return 'Tu pago está siendo revisado por el admin';
      case 'Confirmada': return 'Tu reserva está confirmada. ¡Que disfrutes!';
      case 'Cancelada': return 'Esta reserva fue cancelada';
      case 'Terminada': return 'Esta reserva ya fue realizada';
      default: return 'Reserva creada, pendiente de pago';
    }
  }
}

class ReservaModel {
  final String id;
  final String servicio;
  final String espacio;
  final String fecha;
  final String hora;
  final String estado;
  final String usuario;
  final String codigoReserva;

  ReservaModel({
    required this.id,
    required this.servicio,
    required this.espacio,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.usuario,
    required this.codigoReserva,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['_id'] ?? '',
      servicio: json['servicio']?['nombre'] ?? 'Servicio',
      espacio: json['espacio']?['nombre'] ?? 'Espacio',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      estado: json['estado'] ?? 'Pendiente',
      usuario: json['usuario']?['nombre'] ?? 'Usuario',
      codigoReserva: json['codigoReserva'] ?? '',
    );
  }
}