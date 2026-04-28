import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutterapp/config.dart';

class ReservaFlowPage extends StatefulWidget {
  final Map<String, dynamic> servicio;
  final Map<String, dynamic> espacio;

  const ReservaFlowPage({super.key, required this.servicio, required this.espacio});

  @override
  State<ReservaFlowPage> createState() => _ReservaFlowPageState();
}

class _ReservaFlowPageState extends State<ReservaFlowPage> {
  static const _primary = Color(0xFF19382F);
  int _step = 0; // 0=fecha, 1=horario, 2=resumen, 3=pago, 4=comprobante
  DateTime _selectedDay = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  Map<String, dynamic>? _selectedHorario;
  List<Map<String, dynamic>> _horarios = [];
  List<String> _horasOcupadas = [];
  bool _loadingHorarios = false;
  bool _loading = false;
  String? _reservaId;
  String? _codigoReserva;
  String? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
      _token = prefs.getString('userToken');
    });
  }

  Future<void> _fetchHorarios() async {
    setState(() { _loadingHorarios = true; _horasOcupadas = []; _selectedHorario = null; });
    final sid = widget.servicio['_id'];
    final fecha = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2,'0')}-${_selectedDay.day.toString().padLeft(2,'0')}";

    try {
      // Horarios del servicio
      final hs = List<Map<String, dynamic>>.from(widget.servicio['horarios'] ?? []);

      // Horarios ocupados para esa fecha
      final res = await http.get(Uri.parse('${Config.baseUrl}/api/reservas/ocupados/$sid?fecha=$fecha'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _horasOcupadas = List<String>.from(data['horasOcupadas'] ?? []);
      }

      // Filtrar por día de la semana (diasAbierto: 1=Lun...7=Dom)
      final diasAbierto = List<int>.from(widget.servicio['diasAbierto'] ?? [1,2,3,4,5,6,7]);
      int diaSemana = _selectedDay.weekday; // 1=Mon...7=Sun
      if (!diasAbierto.contains(diaSemana)) {
        setState(() { _horarios = []; _loadingHorarios = false; });
        return;
      }

      setState(() { _horarios = hs; _loadingHorarios = false; });
    } catch (_) {
      setState(() { _loadingHorarios = false; });
    }
  }

  Future<void> _crearReserva() async {
    if (_userId == null || _token == null) return;
    setState(() => _loading = true);
    final fecha = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2,'0')}-${_selectedDay.day.toString().padLeft(2,'0')}";
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/api/reservas/crear'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode({
          'usuario': _userId,
          'servicio': widget.servicio['_id'],
          'espacio': widget.espacio['_id'],
          'fecha': fecha,
          'hora': _selectedHorario!['inicio'],
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        setState(() {
          _reservaId = data['reserva']['_id'];
          _codigoReserva = data['reserva']['codigoReserva'];
          _step = 3; // Ir a pago
        });
      } else {
        _snack(data['mensaje'] ?? 'Error al crear reserva');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _subirComprobante(dynamic file) async {
    if (_reservaId == null) return;
    setState(() => _loading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/reservas/$_reservaId/comprobante'));
      request.headers['Authorization'] = 'Bearer $_token';
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('comprobante', bytes, filename: file.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('comprobante', file.path));
      }
      final streamed = await request.send();
      if (streamed.statusCode == 200) {
        setState(() => _step = 5); // Éxito
      } else {
        _snack('Error al subir comprobante');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _loading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.sansita())));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _primary,
        title: Text(_stepTitle(), style: GoogleFonts.sansita(fontWeight: FontWeight.w800, color: _primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { if (_step > 0 && _step < 3) { setState(() => _step--); } else { Navigator.pop(context); } },
        ),
      ),
      body: Stack(children: [
        _buildStep(),
        if (_loading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)))),
      ]),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0: return 'Elige la fecha';
      case 1: return 'Elige el horario';
      case 2: return 'Resumen de reserva';
      case 3: return 'Método de pago';
      case 4: return 'Subir comprobante';
      default: return '¡Reserva enviada!';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _stepFecha();
      case 1: return _stepHorario();
      case 2: return _stepResumen();
      case 3: return _stepPago();
      case 4: return _stepComprobante();
      default: return _stepExito();
    }
  }

  // ─── PASO 0: FECHA ────────────────────────────────────────────────
  Widget _stepFecha() {
    return Column(children: [
      _progreso(1),
      Expanded(
        child: SingleChildScrollView(
          child: Column(children: [
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: _primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                markerDecoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.bold, color: _primary),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: _primary),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: _primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                weekendStyle: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
      _botonSiguiente('Continuar', () async { await _fetchHorarios(); setState(() => _step = 1); }),
    ]);
  }

  // ─── PASO 1: HORARIO ─────────────────────────────────────────────
  Widget _stepHorario() {
    return Column(children: [
      _progreso(2),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, color: _primary, size: 18),
            const SizedBox(width: 10),
            Text('${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
          ]),
        ),
      ),
      Expanded(child: _loadingHorarios
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)))
          : _horarios.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.event_busy_rounded, size: 60, color: _primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('No hay horarios para este día', style: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.4), fontSize: 16)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _horarios.length,
                  itemBuilder: (ctx, i) {
                    final h = _horarios[i];
                    final occupied = _horasOcupadas.contains(h['inicio']);
                    final selected = _selectedHorario == h;
                    return GestureDetector(
                      onTap: occupied ? null : () => setState(() => _selectedHorario = h),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: occupied ? Colors.grey.shade100 : selected ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: occupied ? Colors.grey.shade200 : selected ? _primary : _primary.withValues(alpha: 0.15)),
                          boxShadow: selected ? [BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0,4))] : [],
                        ),
                        child: Row(children: [
                          Icon(occupied ? Icons.lock_rounded : Icons.access_time_rounded,
                              color: occupied ? Colors.grey.shade400 : selected ? Colors.white : _primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${h['inicio']} – ${h['fin']}',
                              style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold,
                                  color: occupied ? Colors.grey.shade400 : selected ? Colors.white : _primary))),
                          if (!occupied) Text('\$${h['precio']}',
                              style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800,
                                  color: selected ? Colors.white : _primary)),
                          if (occupied) Text('Ocupado', style: GoogleFonts.sansita(fontSize: 13, color: Colors.grey.shade400)),
                        ]),
                      ),
                    );
                  },
                )),
      _botonSiguiente('Continuar', _selectedHorario == null ? null : () => setState(() => _step = 2)),
    ]);
  }

  // ─── PASO 2: RESUMEN ──────────────────────────────────────────────
  Widget _stepResumen() {
    final fecha = '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}';
    return Column(children: [
      _progreso(3),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0,8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Resumen', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(widget.espacio['nombre'] ?? 'Espacio', style: GoogleFonts.sansita(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(widget.servicio['nombre'] ?? 'Servicio', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
              const Divider(color: Colors.white24, height: 32),
              _resumenRow(Icons.calendar_today_rounded, 'Fecha', fecha),
              const SizedBox(height: 12),
              _resumenRow(Icons.access_time_rounded, 'Horario', '${_selectedHorario!['inicio']} – ${_selectedHorario!['fin']}'),
              const SizedBox(height: 12),
              _resumenRow(Icons.attach_money_rounded, 'Precio', '\$${_selectedHorario!['precio']}'),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Al confirmar crearás la reserva. Luego deberás realizar el pago para validarla.',
                  style: GoogleFonts.sansita(fontSize: 13, color: Colors.orange.shade800))),
            ]),
          ),
        ]),
      )),
      _botonSiguiente('Confirmar y pagar', _loading ? null : _crearReserva),
    ]);
  }

  Widget _resumenRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
      const SizedBox(width: 10),
      Text('$label: ', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
      Text(value, style: GoogleFonts.sansita(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ]);
  }

  // ─── PASO 3: MÉTODO DE PAGO ───────────────────────────────────────
  Widget _stepPago() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _progreso(4),
        const SizedBox(height: 8),
        Text('¿Cómo quieres pagar?', style: GoogleFonts.sansita(fontSize: 22, fontWeight: FontWeight.w900, color: _primary)),
        const SizedBox(height: 24),
        // Transferencia
        GestureDetector(
          onTap: () => setState(() => _step = 4),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _primary.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,4))]),
            child: Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.account_balance_rounded, color: _primary, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transferencia Bancaria', style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.bold, color: _primary)),
                Text('Transfiere y sube el comprobante', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.5))),
              ])),
              Icon(Icons.chevron_right_rounded, color: _primary),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // Tarjeta - Próximamente
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.credit_card_rounded, color: Colors.grey.shade400, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tarjeta de Crédito/Débito', style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
              Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                child: Text('Próximamente', style: GoogleFonts.sansita(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
            ])),
          ]),
        ),
      ]),
    );
  }

  // ─── PASO 4: COMPROBANTE ─────────────────────────────────────────
  Widget _stepComprobante() {
    final cuentas = List<Map<String, dynamic>>.from(widget.espacio['cuentasBancarias'] ?? []);
    return Column(children: [
      _progreso(4),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cuentas disponibles', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
          const SizedBox(height: 12),
          if (cuentas.isEmpty)
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
              child: Text('El administrador no ha registrado cuentas bancarias aún. Contáctalo directamente.',
                  style: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.5), fontSize: 14)))
          else
            ...cuentas.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _primary.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,3))]),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.account_balance_rounded, color: _primary, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['banco'] ?? '', style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: _primary)),
                  Text('Titular: ${c['titular'] ?? ''}', style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5))),
                  Text('Cuenta: ${c['numeroCuenta'] ?? ''}', style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5))),
                  if ((c['tipoCuenta'] ?? '').isNotEmpty)
                    Text('Tipo: ${c['tipoCuenta']}', style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5))),
                ])),
              ]),
            )),
          const SizedBox(height: 24),
          Text('Subir comprobante de pago', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loading ? null : _pickComprobante,
            child: Container(
              height: 120,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.15), style: BorderStyle.solid)),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.cloud_upload_rounded, size: 36, color: _primary.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('Toca para subir la imagen del comprobante', style: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.5), fontSize: 13)),
              ])),
            ),
          ),
        ]),
      )),
    ]);
  }

  Future<void> _pickComprobante() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) await _subirComprobante(f);
  }

  // ─── PASO 5: ÉXITO ────────────────────────────────────────────────
  Widget _stepExito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 48)),
          const SizedBox(height: 24),
          Text('¡Comprobante enviado!', style: GoogleFonts.sansita(fontSize: 26, fontWeight: FontWeight.w900, color: _primary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Tu reserva está en espera de validación por el administrador. Te notificaremos cuando sea confirmada.',
              style: GoogleFonts.sansita(fontSize: 15, color: _primary.withValues(alpha: 0.5), height: 1.5), textAlign: TextAlign.center),
          if (_codigoReserva != null) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text('Tu código de reserva', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                const SizedBox(height: 8),
                Text(_codigoReserva!, style: GoogleFonts.sansita(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
              ]),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('Ir a mis reservas', style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.w800)),
          )),
        ]),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  Widget _progreso(int actual) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(children: List.generate(4, (i) => Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 4, margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
          decoration: BoxDecoration(
            color: i < actual ? _primary : _primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ))),
    );
  }

  Widget _botonSiguiente(String label, VoidCallback? onTap) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: _primary, disabledBackgroundColor: _primary.withValues(alpha: 0.3),
            foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: Text(label, style: GoogleFonts.sansita(fontSize: 17, fontWeight: FontWeight.w800)),
        )),
      ),
    );
  }
}
