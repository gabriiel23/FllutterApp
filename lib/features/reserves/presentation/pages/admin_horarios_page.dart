import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

class AdminHorariosPage extends StatefulWidget {
  final Map<String, dynamic> servicio;
  const AdminHorariosPage({super.key, required this.servicio});

  @override
  State<AdminHorariosPage> createState() => _AdminHorariosPageState();
}

class _AdminHorariosPageState extends State<AdminHorariosPage> {
  static const _primary = Color(0xFF19382F);

  List<int> _diasAbierto = [];
  List<Map<String, dynamic>> _horarios = [];
  double _precioDia = 0;
  double _precioNoche = 0;
  String _horaInicioNoche = '18:00';
  bool _loading = false;

  // Control por fecha
  DateTime _fechaControl = DateTime.now();
  List<String> _horasBloqueadasFecha = [];
  bool _loadingBloqueos = false;

  final _precioDiaCtrl = TextEditingController();
  final _precioNocheCtrl = TextEditingController();
  final _horaNocheCtrl = TextEditingController();

  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _diasNombres = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    final da = s['diasAbierto'] as List?;
    _diasAbierto = da?.map((e) => int.parse(e.toString())).toList() ?? [];
    _precioDia = (s['precioDia'] ?? 0).toDouble();
    _precioNoche = (s['precioNoche'] ?? 0).toDouble();
    _horaInicioNoche = s['horaInicioNoche'] ?? '18:00';
    _horarios = List<Map<String, dynamic>>.from(s['horarios'] ?? []);

    _precioDiaCtrl.text = _precioDia > 0 ? _precioDia.toString() : '';
    _precioNocheCtrl.text = _precioNoche > 0 ? _precioNoche.toString() : '';
    _horaNocheCtrl.text = _horaInicioNoche;
  }

  @override
  void dispose() {
    _precioDiaCtrl.dispose();
    _precioNocheCtrl.dispose();
    _horaNocheCtrl.dispose();
    super.dispose();
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

  // Genera horarios automáticos (07:00–00:00 en bloques de 1 hora)
  void _generarHorarios() {
    if (_diasAbierto.isEmpty) { _snack('Selecciona al menos un día', error: true); return; }
    final pDia = double.tryParse(_precioDiaCtrl.text) ?? 0;
    final pNoche = double.tryParse(_precioNocheCtrl.text) ?? 0;
    final horaNoche = _horaNocheCtrl.text.trim();

    final nuevos = <Map<String, dynamic>>[];
    // 07:00 a 23:00 (último slot 23:00–00:00)
    for (int h = 7; h < 24; h++) {
      final inicio = '${h.toString().padLeft(2, '0')}:00';
      final fin = h == 23 ? '00:00' : '${(h + 1).toString().padLeft(2, '0')}:00';
      final esNoche = horaNoche.isNotEmpty && inicio.compareTo(horaNoche) >= 0;
      final precio = esNoche ? pNoche : pDia;
      nuevos.add({'inicio': inicio, 'fin': fin, 'precio': precio, 'disponible': true});
    }
    setState(() => _horarios = nuevos);
    _snack('Horarios generados (${nuevos.length} bloques de 1 hora, 07:00–00:00)');
  }

  Future<void> _guardar() async {
    if (_diasAbierto.isEmpty) { _snack('Selecciona al menos un día', error: true); return; }
    if (_horarios.isEmpty) { _snack('Genera o agrega al menos un horario', error: true); return; }

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final sid = widget.servicio['_id'];

      final pDia = double.tryParse(_precioDiaCtrl.text) ?? 0;
      final pNoche = double.tryParse(_precioNocheCtrl.text) ?? pDia;
      final horaNoche = _horaNocheCtrl.text.trim();

      final horariosActualizados = _horarios.map((h) {
        final esNoche = horaNoche.isNotEmpty && (h['inicio'] as String).compareTo(horaNoche) >= 0;
        return {...h, 'precio': esNoche ? pNoche : pDia};
      }).toList();

      final body = jsonEncode({
        'diasAbierto': _diasAbierto,
        'precioDia': pDia,
        'precioNoche': pNoche,
        'horaInicioNoche': horaNoche,
        'horarios': horariosActualizados,
      });

      final resp = await http.put(
        Uri.parse('${Config.baseUrl}/api/$sid'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode == 200) {
        _snack('¡Horarios guardados!');
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack('Error al guardar', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    setState(() => _loading = false);
  }

  // ── BLOQUEOS POR FECHA ───────────────────────────────────────────────────
  String _fechaStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _cargarBloqueosFecha() async {
    setState(() => _loadingBloqueos = true);
    try {
      final sid = widget.servicio['_id'];
      final fecha = _fechaStr(_fechaControl);
      final resp = await http.get(Uri.parse('${Config.baseUrl}/api/$sid/bloqueos?fecha=$fecha'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _horasBloqueadasFecha = List<String>.from(data['horasBloqueadas'] ?? []));
      }
    } catch (_) {}
    setState(() => _loadingBloqueos = false);
  }

  Future<void> _guardarBloqueosFecha() async {
    setState(() => _loadingBloqueos = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final sid = widget.servicio['_id'];
      final fecha = _fechaStr(_fechaControl);
      final resp = await http.post(
        Uri.parse('${Config.baseUrl}/api/$sid/bloqueos'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'fecha': fecha, 'horasBloqueadas': _horasBloqueadasFecha}),
      );
      if (resp.statusCode == 200) {
        _snack('Bloqueos del ${_fechaControl.day}/${_fechaControl.month} guardados');
      } else {
        _snack('Error al guardar bloqueos', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
    setState(() => _loadingBloqueos = false);
  }

  void _toggleBloqueoHora(String hora) {
    setState(() {
      if (_horasBloqueadasFecha.contains(hora)) {
        _horasBloqueadasFecha.remove(hora);
      } else {
        _horasBloqueadasFecha.add(hora);
      }
    });
  }

  void _editarPrecioHorario(int index) {
    final h = _horarios[index];
    final ctrl = TextEditingController(text: h['precio'].toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Editar precio: ${h['inicio']} – ${h['fin']}', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.sansita(fontSize: 20, fontWeight: FontWeight.bold, color: _primary),
              decoration: InputDecoration(
                labelText: 'Precio (\$)',
                labelStyle: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.attach_money_rounded, color: _primary),
                filled: true, fillColor: _primary.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                setState(() => _horarios[index] = {...h, 'precio': double.tryParse(ctrl.text) ?? 0});
                Navigator.pop(ctx);
              },
              child: Text('Guardar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Horarios – ${widget.servicio['nombre'] ?? ''}',
            style: GoogleFonts.sansita(color: _primary, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _primary,
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF19382F))))
          else
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('Guardar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: _primary),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Días de apertura ──
          _sectionTitle(Icons.calendar_today_rounded, 'Días de apertura'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(7, (i) {
              final dia = i + 1;
              final sel = _diasAbierto.contains(dia);
              return GestureDetector(
                onTap: () => setState(() => sel ? _diasAbierto.remove(dia) : _diasAbierto.add(dia)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: sel ? _primary : _primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.12)),
                  ),
                  child: Center(child: Text(_dias[i], style: GoogleFonts.sansita(
                      color: sel ? Colors.white : _primary, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
              );
            }),
          ),
          if (_diasAbierto.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _diasAbierto.map((d) => _diasNombres[d - 1]).join(', '),
              style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5)),
            ),
          ],

          const SizedBox(height: 28),

          // ── Precios ──
          _sectionTitle(Icons.attach_money_rounded, 'Precios por hora'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildInput(_precioDiaCtrl, 'Precio Día (\$)', Icons.wb_sunny_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildInput(_precioNocheCtrl, 'Precio Noche (\$)', Icons.nights_stay_rounded)),
          ]),
          const SizedBox(height: 14),
          _buildInput(_horaNocheCtrl, 'Inicio tarifa nocturna (HH:MM)', Icons.schedule_rounded),
          const SizedBox(height: 6),
          Text('Ej: "18:00" – A partir de esa hora se aplica el precio nocturno.',
              style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.4))),

          const SizedBox(height: 28),

          // ── Generar slots automáticos ──
          _sectionTitle(Icons.auto_fix_high_rounded, 'Slots de horario'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generarHorarios,
            icon: Icon(Icons.refresh_rounded, color: _primary, size: 18),
            label: Text('Generar horarios automáticos (06:00–22:00 en bloques de 1h)',
                style: GoogleFonts.sansita(color: _primary, fontSize: 13, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 6),
          Text('También puedes ajustar el precio de cada slot individualmente tocándolo.',
              style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.4))),

          const SizedBox(height: 16),
          if (_horarios.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: _primary.withValues(alpha: 0.08))),
              child: Center(child: Text('No hay horarios configurados aún.\nUsa "Generar horarios automáticos" para empezar.',
                  style: GoogleFonts.sansita(color: _primary.withValues(alpha: 0.4), fontSize: 14), textAlign: TextAlign.center)),
            )
          else
            _buildHorariosGrid(),

          const SizedBox(height: 40),

          // ── Control de fechas específicas ──
          _sectionTitle(Icons.event_busy_rounded, 'Bloqueos por fecha'),
          const SizedBox(height: 6),
          Text(
            'Bloquea horas específicas en una fecha (ej: reservas físicas, mantenimiento). Las horas bloqueadas no aparecerán disponibles para los usuarios.',
            style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 14),

          // Selector de fecha
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaControl,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (ctx, child) => Theme(data: ThemeData(colorSchemeSeed: _primary), child: child!),
              );
              if (picked != null) {
                setState(() { _fechaControl = picked; _horasBloqueadasFecha = []; });
                await _cargarBloqueosFecha();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withValues(alpha: 0.12)),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: _primary, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  '${_fechaControl.day.toString().padLeft(2,'0')}/${_fechaControl.month.toString().padLeft(2,'0')}/${_fechaControl.year}',
                  style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.bold, color: _primary),
                )),
                Text('Cambiar', style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5))),
                Icon(Icons.chevron_right_rounded, color: _primary.withValues(alpha: 0.3), size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Grid de horas bloqueables
          if (_loadingBloqueos)
            const Center(child: CircularProgressIndicator(color: Color(0xFF19382F)))
          else if (_horarios.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
              child: Text('Primero genera los horarios base arriba.', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.4)), textAlign: TextAlign.center),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6),
              itemCount: _horarios.length,
              itemBuilder: (_, i) {
                final h = _horarios[i];
                final hora = h['inicio'] as String;
                final bloqueado = _horasBloqueadasFecha.contains(hora);
                return GestureDetector(
                  onTap: () => _toggleBloqueoHora(hora),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: bloqueado ? Colors.red.shade400 : _primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bloqueado ? Colors.red.shade300 : _primary.withValues(alpha: 0.1)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        bloqueado ? Icons.block_rounded : Icons.access_time_rounded,
                        size: 14,
                        color: bloqueado ? Colors.white : _primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(hora, style: GoogleFonts.sansita(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: bloqueado ? Colors.white : _primary,
                      )),
                    ]),
                  ),
                );
              },
            ),

          if (!_loadingBloqueos && _horarios.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              if (_horasBloqueadasFecha.isNotEmpty)
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() => _horasBloqueadasFecha = []),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Limpiar', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                )),
              if (_horasBloqueadasFecha.isNotEmpty) const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: _loadingBloqueos ? null : _guardarBloqueosFecha,
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(
                  _horasBloqueadasFecha.isEmpty ? 'Sin bloqueos (guardar)' : 'Guardar ${_horasBloqueadasFecha.length} bloqueo(s)',
                  style: GoogleFonts.sansita(fontWeight: FontWeight.bold),
                ),
              )),
            ]),
          ],

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHorariosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.5,
      ),
      itemCount: _horarios.length,
      itemBuilder: (_, i) {
        final h = _horarios[i];
        final esNoche = _horaNocheCtrl.text.isNotEmpty && (h['inicio'] as String).compareTo(_horaNocheCtrl.text) >= 0;
        return GestureDetector(
          onTap: () => _editarPrecioHorario(i),
          child: Container(
            decoration: BoxDecoration(
              color: esNoche ? const Color(0xFF19382F) : _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: esNoche ? _primary : _primary.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${h['inicio']}', style: GoogleFonts.sansita(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: esNoche ? Colors.white : _primary)),
              Text('\$${h['precio']}', style: GoogleFonts.sansita(
                  fontSize: 12, color: esNoche ? Colors.white.withValues(alpha: 0.75) : _primary.withValues(alpha: 0.55))),
              if (esNoche)
                Icon(Icons.nights_stay_rounded, size: 11, color: Colors.white.withValues(alpha: 0.5))
            ]),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: _primary)),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
    ]);
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.sansita(fontSize: 15, color: _primary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: _primary.withValues(alpha: 0.4), size: 18),
        filled: true, fillColor: _primary.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primary.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primary.withValues(alpha: 0.25), width: 1.5)),
      ),
    );
  }
}
