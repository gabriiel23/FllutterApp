import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutterapp/config.dart';
import 'package:flutterapp/features/reserves/presentation/pages/admin_horarios_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/validar_qr_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/admin_nueva_reserva_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/admin_reservas_page.dart';

class HomeAdminPage extends StatefulWidget {
  @override
  _HomeAdminPageState createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  DateTime _selectedDay = _normalize(DateTime.now());
  String? espacioId;
  String? nombreUsuario;
  List<Reserva> todasLasReservas = [];
  List<Map<String, dynamic>> _servicios = [];
  Map<String, dynamic>? _espacio;
  bool isLoading = true;

  final Color _primaryDeep = const Color(0xFF19382F);

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _cargarNombreUsuario();
    _cargarEspacioId();
  }

  Future<void> _fetchServicios() async {
    if (espacioId == null) return;
    try {
      final resp = await http.get(Uri.parse('${Config.baseUrl}/api/$espacioId'));
      if (resp.statusCode == 200) {
        setState(() => _servicios = List<Map<String, dynamic>>.from(jsonDecode(resp.body)));
      }
      // Also fetch espacio info
      final respE = await http.get(Uri.parse('${Config.baseUrl}/api/espacio/buscar/$espacioId'));
      if (respE.statusCode == 200) {
        setState(() => _espacio = jsonDecode(respE.body));
      }
    } catch (_) {}
  }

  Future<void> _cargarNombreUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('userToken');
    if (userId != null && token != null) {
      try {
        final nombre = await _fetchNombre(userId, token);
        setState(() => nombreUsuario = nombre);
        await prefs.setString('nombre_usuario', nombre);
      } catch (_) {
        setState(() => nombreUsuario = 'Admin');
      }
    } else {
      setState(() => nombreUsuario = 'Admin');
    }
  }

  Future<String> _fetchNombre(String userId, String token) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/usuario/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['nombre'];
    }
    throw Exception('Error al obtener nombre');
  }

  Future<void> _cargarEspacioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEspacioId = prefs.getString('espacio_id');
    if (storedEspacioId != null) {
      setState(() => espacioId = storedEspacioId);
      await obtenerTodasLasReservas();
    } else {
      String? userId = prefs.getString('userId');
      if (userId != null) {
        try {
          final response = await http.get(Uri.parse('${Config.baseUrl}/api/espacio/espacios-deportivos/$userId'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data is List && data.isNotEmpty) {
              String fetchedId = data[0]['_id'];
              await prefs.setString('espacio_id', fetchedId);
              setState(() => espacioId = fetchedId);
              await obtenerTodasLasReservas();
              await _fetchServicios();
            } else {
               setState(() => isLoading = false);
            }
          } else {
             setState(() => isLoading = false);
          }
        } catch(e) {
             setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> obtenerTodasLasReservas() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/reservas/espacio/$espacioId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          todasLasReservas = data.map((j) => Reserva.fromJson(j)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  List<Reserva> get _reservasDelDia => todasLasReservas
      .where(
          (r) => isSameDay(_normalize(DateTime.parse(r.fecha)), _selectedDay))
      .toList();



  // Cambiar estado de reserva
  Future<void> _cambiarEstado(String id, String estado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      await http.patch(
        Uri.parse('${Config.baseUrl}/api/reservas/$id/estado'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'estado': estado}),
      );
      await obtenerTodasLasReservas();
    } catch (_) {}
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: obtenerTodasLasReservas,
              color: _primaryDeep,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Acciones rápidas ──
                    _buildAccionesRapidas(),
                    // ── Reservas del día ──
                    _buildReservasList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
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
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
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
                              size: 22, color: _primaryDeep),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 42),
                  Material(
                    color: _primaryDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.settings),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.settings_outlined,
                            size: 22, color: _primaryDeep),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fila 2: Icono + Título
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
                    child: Icon(Icons.dashboard_rounded,
                        size: 24, color: _primaryDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hola, ${nombreUsuario ?? 'Admin'}',
                      style: GoogleFonts.sansita(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _primaryDeep,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fila 3: Descripción
              Text(
                'Panel de gestión de reservas',
                style: GoogleFonts.sansita(
                  fontSize: 15,
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

  // ── ACCIONES RÁPIDAS ──────────────────────────────────────────────────────
  Widget _buildAccionesRapidas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(Icons.bolt_rounded, 'Acciones rápidas'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _accionBtn(Icons.qr_code_scanner_rounded, 'Validar\nReserva', Colors.green.shade600, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ValidarQrPage()));
          })),
          const SizedBox(width: 12),
          Expanded(child: _accionBtn(Icons.schedule_rounded, 'Gestionar\nHorarios', _primaryDeep, () {
            if (_servicios.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('No hay servicios configurados', style: GoogleFonts.sansita()),
                backgroundColor: _primaryDeep,
              ));
              return;
            }
            _showSeleccionServicioHorarios();
          })),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _accionBtn(Icons.add_circle_rounded, 'Reservar\nAhora', Colors.blue.shade700, () {
            if (_servicios.isEmpty) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AdminNuevaReservaPage(
                servicios: _servicios,
                espacio: _espacio ?? {'_id': espacioId, 'nombre': 'Espacio'},
              ),
            )).then((r) { if (r == true) obtenerTodasLasReservas(); });
          })),
          const SizedBox(width: 12),
          Expanded(child: _accionBtn(Icons.pending_actions_rounded, 'Validar\nPagos', Colors.orange.shade700, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AdminReservasPage(),
            )).then((_) => obtenerTodasLasReservas());
          })),
        ]),
      ]),
    );
  }

  Widget _accionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: color), maxLines: 2)),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.4), size: 18),
        ]),
      ),
    );
  }

  void _showSeleccionServicioHorarios() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Selecciona un servicio', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: _primaryDeep)),
          const SizedBox(height: 16),
          ..._servicios.map((s) => GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AdminHorariosPage(servicio: Map<String, dynamic>.from(s)),
              )).then((_) => _fetchServicios());
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryDeep.withValues(alpha: 0.1))),
              child: Row(children: [
                Icon(Icons.sports_rounded, color: _primaryDeep, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(s['nombre'] ?? '', style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDeep))),
                Icon(Icons.chevron_right_rounded, color: _primaryDeep.withValues(alpha: 0.3)),
              ]),
            ),
          )),
        ])),
      ),
    );
  }

  // ── LISTA RESERVAS ────────────────────────────────────────────────────────
  Widget _buildReservasList() {
    final reservas = _reservasDelDia;
    final fechaLabel =
        '${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(Icons.list_alt_rounded, 'Reservas del día'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _primaryDeep.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fechaLabel,
                  style: GoogleFonts.sansita(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryDeep.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (reservas.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: reservas.map((r) => _buildReservaCard(r)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva) {
    Color statusColor;
    IconData statusIcon;
    switch (reserva.estado) {
      case 'Confirmada':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Cancelada':
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'EsperandoValidacion':
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      default:
        statusColor = Colors.blue.shade600;
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.07)),
        boxShadow: [BoxShadow(color: _primaryDeep.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 58, padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _primaryDeep.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(Icons.access_time_rounded, size: 14, color: _primaryDeep.withValues(alpha: 0.5)),
                const SizedBox(height: 4),
                Text(reserva.hora, style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.w800, color: _primaryDeep), textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reserva.servicio, style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.w800, color: _primaryDeep), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 13, color: _primaryDeep.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(reserva.usuario, style: GoogleFonts.sansita(fontSize: 13, color: _primaryDeep.withValues(alpha: 0.45))),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(statusIcon, size: 13, color: statusColor),
                const SizedBox(width: 4),
                Text(_estadoCorto(reserva.estado), style: GoogleFonts.sansita(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ]),
            ),
          ]),
        ),
        // Acciones admin
        if (reserva.estado == 'EsperandoValidacion') ...[  
          Divider(height: 1, color: _primaryDeep.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _cambiarEstado(reserva.id, 'Cancelada'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text('Rechazar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 13)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () => _cambiarEstado(reserva.id, 'Confirmada'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0),
                child: Text('Confirmar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 13)),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  String _estadoCorto(String estado) {
    switch (estado) {
      case 'EsperandoValidacion': return 'Validando';
      case 'Confirmada': return 'Confirmada';
      case 'Cancelada': return 'Cancelada';
      case 'Terminada': return 'Terminada';
      default: return 'Pendiente';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _primaryDeep.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryDeep.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 48, color: _primaryDeep.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'Sin reservas este día',
            style: GoogleFonts.sansita(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryDeep.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona otro día en el calendario',
            style: GoogleFonts.sansita(
              fontSize: 13,
              color: _primaryDeep.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _primaryDeep),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.sansita(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryDeep,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class Reserva {
  final String id;
  final String servicio;
  final String fecha;
  final String hora;
  final String estado;
  final String usuario;

  Reserva({
    required this.id,
    required this.servicio,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.usuario,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json["_id"],
      servicio: json["servicio"]?["nombre"] ?? "Servicio Desconocido",
      fecha: json["fecha"] ?? "",
      hora: json["hora"] ?? "",
      estado: json["estado"] ?? "Pendiente",
      usuario: json["usuario"]?["nombre"] ?? "Usuario Desconocido",
    );
  }
}
