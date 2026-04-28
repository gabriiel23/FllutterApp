import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

/// Flujo de reserva presencial para el admin.
/// El cliente llega físicamente — no requiere QR ni comprobante.
class AdminNuevaReservaPage extends StatefulWidget {
  final List<Map<String, dynamic>> servicios;
  final Map<String, dynamic> espacio;

  const AdminNuevaReservaPage({
    super.key,
    required this.servicios,
    required this.espacio,
  });

  @override
  State<AdminNuevaReservaPage> createState() => _AdminNuevaReservaPageState();
}

class _AdminNuevaReservaPageState extends State<AdminNuevaReservaPage> {
  static const _primary = Color(0xFF19382F);

  // Pasos: 0 Servicio, 1 Fecha, 2 Horario, 3 Datos cliente
  int _step = 0;

  Map<String, dynamic>? _servicioSel;
  DateTime _fechaSel = DateTime.now();
  String? _horaSel;
  String _metodoPago = 'Efectivo';

  final _nombreCtrl = TextEditingController();
  List<String> _horasOcupadas = [];
  bool _loadingHoras = false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fechaStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _horariosServicio {
    if (_servicioSel == null) return [];
    return List<Map<String, dynamic>>.from(_servicioSel!['horarios'] ?? []);
  }

  List<Map<String, dynamic>> get _horariosDisponibles =>
      _horariosServicio.where((h) {
        final inicio = h['inicio'] as String? ?? '';
        final disponible = h['disponible'] as bool? ?? true;
        return disponible && !_horasOcupadas.contains(inicio);
      }).toList();

  Future<void> _cargarOcupados() async {
    if (_servicioSel == null) return;
    setState(() { _loadingHoras = true; _horaSel = null; });
    try {
      final sid = _servicioSel!['_id'];
      final fecha = _fechaStr(_fechaSel);
      final resp = await http.get(
        Uri.parse('${Config.baseUrl}/api/reservas/ocupados/$sid?fecha=$fecha'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _horasOcupadas = List<String>.from(data['horasOcupadas'] ?? []));
      }
    } catch (_) {}
    setState(() => _loadingHoras = false);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
      backgroundColor: error ? Colors.red.shade600 : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _crearReserva() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _snack('Ingresa el nombre del cliente', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final body = jsonEncode({
        'usuario': userId,
        'servicio': _servicioSel!['_id'],
        'espacio': widget.espacio['_id'],
        'fecha': _fechaStr(_fechaSel),
        'hora': _horaSel,
        'nombreCliente': _nombreCtrl.text.trim(),
        'metodoPago': _metodoPago,
      });

      final resp = await http.post(
        Uri.parse('${Config.baseUrl}/api/reservas/presencial'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body,
      );

      if (resp.statusCode == 201) {
        if (mounted) _showExito();
      } else {
        final err = jsonDecode(resp.body)['mensaje'] ?? 'Error al crear reserva';
        _snack(err, error: true);
      }
    } catch (e) {
      _snack('Error de conexión', error: true);
    }
    setState(() => _guardando = false);
  }

  void _showExito() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 40),
          ),
          const SizedBox(height: 20),
          Text('¡Reserva creada!', style: GoogleFonts.sansita(fontSize: 26, fontWeight: FontWeight.w900, color: _primary)),
          const SizedBox(height: 8),
          Text(
            '${_nombreCtrl.text.trim()} queda reservado para\n${_servicioSel!['nombre']} el ${_fechaSel.day}/${_fechaSel.month}/${_fechaSel.year} a las $_horaSel.',
            style: GoogleFonts.sansita(fontSize: 14, color: _primary.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.payments_rounded, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text('Pago: $_metodoPago', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Listo', style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Nueva Reserva Presencial', style: GoogleFonts.sansita(color: _primary, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _primary,
      ),
      body: Column(children: [
        _buildStepBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildStep(),
        )),
        _buildBottomBar(),
      ]),
    );
  }

  Widget _buildStepBar() {
    final steps = ['Servicio', 'Fecha', 'Horario', 'Cliente'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: List.generate(steps.length, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(child: Row(children: [
          Expanded(child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done ? Colors.green.shade600 : active ? _primary : _primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : Text('${i + 1}', style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : _primary.withValues(alpha: 0.4)))),
            ),
            const SizedBox(height: 4),
            Text(steps[i], style: GoogleFonts.sansita(fontSize: 10, color: active ? _primary : _primary.withValues(alpha: 0.4), fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ])),
          if (i < steps.length - 1)
            Container(height: 1, width: 16, color: _primary.withValues(alpha: 0.12)),
        ]));
      })),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildStepServicio();
      case 1: return _buildStepFecha();
      case 2: return _buildStepHorario();
      case 3: return _buildStepCliente();
      default: return const SizedBox();
    }
  }

  // Step 0 — Selección de servicio
  Widget _buildStepServicio() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('¿Qué servicio desea reservar?', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: _primary)),
      const SizedBox(height: 6),
      Text('Selecciona el servicio para el cliente.', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.45))),
      const SizedBox(height: 20),
      ...widget.servicios.map((s) {
        final sel = _servicioSel?['_id'] == s['_id'];
        final horarios = (s['horarios'] as List?) ?? [];
        final info = horarios.isNotEmpty
            ? '${horarios.first['inicio']} – ${horarios.last['fin']}'
            : 'Sin horario configurado';
        return GestureDetector(
          onTap: () => setState(() { _servicioSel = Map<String, dynamic>.from(s); }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.1), width: sel ? 2 : 1),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: sel ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: (sel ? Colors.white : _primary).withValues(alpha: sel ? 0.15 : 0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.sports_rounded, color: sel ? Colors.white : _primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['nombre'] ?? '', style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: sel ? Colors.white : _primary)),
                Text(info, style: GoogleFonts.sansita(fontSize: 12, color: (sel ? Colors.white : _primary).withValues(alpha: 0.55))),
              ])),
              if (sel) Icon(Icons.check_circle_rounded, color: Colors.white.withValues(alpha: 0.8)),
            ]),
          ),
        );
      }),
    ]);
  }

  // Step 1 — Selección de fecha
  Widget _buildStepFecha() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('¿Para qué fecha?', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: _primary)),
      const SizedBox(height: 6),
      Text('Selecciona el día de la reserva.', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.45))),
      const SizedBox(height: 24),
      // Picker de fecha simple — próximos 30 días como chips desplazables
      SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 30,
          itemBuilder: (_, i) {
            final d = DateTime.now().add(Duration(days: i));
            final sel = _fechaStr(d) == _fechaStr(_fechaSel);
            final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
            return GestureDetector(
              onTap: () => setState(() => _fechaSel = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 10),
                width: 58,
                decoration: BoxDecoration(
                  color: sel ? _primary : _primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.1)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dias[d.weekday % 7], style: GoogleFonts.sansita(fontSize: 11, color: sel ? Colors.white.withValues(alpha: 0.7) : _primary.withValues(alpha: 0.5))),
                  Text('${d.day}', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: sel ? Colors.white : _primary)),
                  Text(_mesCorto(d.month), style: GoogleFonts.sansita(fontSize: 11, color: sel ? Colors.white.withValues(alpha: 0.7) : _primary.withValues(alpha: 0.5))),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, color: _primary, size: 18),
          const SizedBox(width: 12),
          Text(
            '${_fechaSel.day.toString().padLeft(2, '0')}/${_fechaSel.month.toString().padLeft(2, '0')}/${_fechaSel.year}',
            style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
          ),
        ]),
      ),
    ]);
  }

  String _mesCorto(int m) => ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'][m - 1];

  // Step 2 — Selección de horario
  Widget _buildStepHorario() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('¿A qué hora?', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: _primary)),
      const SizedBox(height: 6),
      Text('Selecciona el horario disponible.', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.45))),
      const SizedBox(height: 20),
      if (_loadingHoras)
        const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)))
      else if (_horariosDisponibles.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text('No hay horarios disponibles para esta fecha.', style: GoogleFonts.sansita(color: Colors.orange.shade800))),
          ]),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
          ),
          itemCount: _horariosDisponibles.length,
          itemBuilder: (_, i) {
            final h = _horariosDisponibles[i];
            final inicio = h['inicio'] as String;
            final sel = _horaSel == inicio;
            final precio = (h['precio'] ?? 0).toStringAsFixed(0);
            return GestureDetector(
              onTap: () => setState(() => _horaSel = inicio),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: sel ? _primary : _primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.1), width: sel ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(inicio, style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.w800, color: sel ? Colors.white : _primary)),
                  Text('\$$precio', style: GoogleFonts.sansita(fontSize: 11, color: (sel ? Colors.white : _primary).withValues(alpha: 0.6))),
                ]),
              ),
            );
          },
        ),

      // También muestra los ocupados (vista de info)
      if (!_loadingHoras && _horasOcupadas.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Horarios no disponibles', style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.5))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _horasOcupadas.map((h) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
            child: Text(h, style: GoogleFonts.sansita(fontSize: 12, color: Colors.red.shade700)),
          ),
        ).toList()),
      ],
    ]);
  }

  // Step 3 — Datos del cliente
  Widget _buildStepCliente() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Datos del cliente', style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.w900, color: _primary)),
      const SizedBox(height: 6),
      Text('Ingresa el nombre de quien reserva.', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.45))),
      const SizedBox(height: 24),

      // Nombre del cliente
      Text('Nombre del cliente *', style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
      const SizedBox(height: 8),
      TextField(
        controller: _nombreCtrl,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.w600, color: _primary),
        decoration: InputDecoration(
          hintText: 'Ej: Juan Pérez',
          hintStyle: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.3)),
          prefixIcon: Icon(Icons.person_rounded, color: _primary.withValues(alpha: 0.4)),
          filled: true, fillColor: _primary.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary, width: 1.5)),
        ),
      ),

      const SizedBox(height: 28),

      // Método de pago
      Text('Método de pago', style: GoogleFonts.sansita(fontSize: 14, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
      const SizedBox(height: 12),
      ...['Efectivo', 'Transferencia'].map((m) {
        final sel = _metodoPago == m;
        return GestureDetector(
          onTap: () => setState(() => _metodoPago = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: sel ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.1), width: sel ? 2 : 1),
            ),
            child: Row(children: [
              Icon(m == 'Efectivo' ? Icons.payments_rounded : Icons.account_balance_rounded,
                  color: sel ? Colors.white : _primary.withValues(alpha: 0.6), size: 20),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m, style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: sel ? Colors.white : _primary)),
                Text(m == 'Efectivo' ? 'El cliente pagó en efectivo' : 'Pago por transferencia bancaria',
                    style: GoogleFonts.sansita(fontSize: 12, color: (sel ? Colors.white : _primary).withValues(alpha: 0.55))),
              ])),
              if (sel) Icon(Icons.check_circle_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
            ]),
          ),
        );
      }),

      const SizedBox(height: 28),

      // Resumen
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: _primary.withValues(alpha: 0.1))),
        child: Column(children: [
          _resumenRow(Icons.sports_rounded, 'Servicio', _servicioSel?['nombre'] ?? ''),
          _divRes(),
          _resumenRow(Icons.calendar_today_rounded, 'Fecha', '${_fechaSel.day}/${_fechaSel.month}/${_fechaSel.year}'),
          _divRes(),
          _resumenRow(Icons.access_time_rounded, 'Hora', _horaSel ?? ''),
        ]),
      ),
    ]);
  }

  Widget _resumenRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 16, color: _primary.withValues(alpha: 0.4)),
      const SizedBox(width: 10),
      Text('$label:', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.5))),
      const Spacer(),
      Text(value, style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: _primary)),
    ]),
  );

  Widget _divRes() => Divider(height: 1, color: _primary.withValues(alpha: 0.07));

  Widget _buildBottomBar() {
    final canNext = switch (_step) {
      0 => _servicioSel != null,
      1 => true,
      2 => _horaSel != null,
      3 => true,
      _ => false,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(top: false, child: Row(children: [
        if (_step > 0) ...[
          OutlinedButton(
            onPressed: () => setState(() => _step--),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primary.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            child: Icon(Icons.arrow_back_rounded, color: _primary),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: ElevatedButton(
          onPressed: canNext ? () async {
            if (_step == 1) {
              // Al avanzar a horarios, cargar ocupados
              await _cargarOcupados();
            }
            if (_step < 3) {
              setState(() => _step++);
            } else {
              await _crearReserva();
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _primary.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _guardando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  _step == 3 ? 'Confirmar reserva' : 'Siguiente',
                  style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        )),
      ])),
    );
  }
}
