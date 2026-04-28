import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/config.dart';

/// Validación por código manual (texto) — el escáner de QR requiere
/// el paquete mobile_scanner que solo funciona en dispositivos físicos,
/// por lo que se ofrece entrada manual compatible con web y emuladores.
class ValidarQrPage extends StatefulWidget {
  const ValidarQrPage({super.key});

  @override
  State<ValidarQrPage> createState() => _ValidarQrPageState();
}

class _ValidarQrPageState extends State<ValidarQrPage> with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF19382F);
  final _codigoCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _reservaEncontrada;
  String? _errorMsg;

  // Lista de reservas escaneadas en esta sesión
  final List<Map<String, dynamic>> _escaneados = [];

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarCodigo(String codigo) async {
    if (codigo.trim().isEmpty) return;
    setState(() { _loading = true; _reservaEncontrada = null; _errorMsg = null; });
    try {
      final resp = await http.get(Uri.parse('${Config.baseUrl}/api/reservas/validar/${codigo.trim().toUpperCase()}'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() => _reservaEncontrada = data);
      } else {
        setState(() => _errorMsg = 'Código no encontrado');
      }
    } catch (_) {
      setState(() => _errorMsg = 'Error de conexión');
    }
    setState(() => _loading = false);
  }

  Future<void> _confirmarReserva(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final resp = await http.patch(
        Uri.parse('${Config.baseUrl}/api/reservas/$reservaId/estado'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'estado': 'Confirmada'}),
      );
      if (resp.statusCode == 200 && mounted) {
        // Agregar a lista de escaneados
        setState(() {
          _escaneados.insert(0, {
            ..._reservaEncontrada!,
            'validadoEn': DateTime.now().toIso8601String(),
          });
          _reservaEncontrada = null;
          _codigoCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Reserva confirmada', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Validar Reservas', style: GoogleFonts.sansita(color: _primary, fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _primary,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _primary,
          unselectedLabelColor: _primary.withValues(alpha: 0.4),
          indicatorColor: _primary,
          labelStyle: GoogleFonts.sansita(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Validar'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'Lista'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildValidarTab(), _buildListaTab()],
      ),
    );
  }

  Widget _buildValidarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ingresar código
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Código de reserva', style: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.sansita(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXX',
                    hintStyle: GoogleFonts.sansita(color: Colors.white.withValues(alpha: 0.3), fontSize: 22, letterSpacing: 4),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _buscarCodigo,
                ),
              ),
              GestureDetector(
                onTap: () => _buscarCodigo(_codigoCtrl.text),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: _loading
                      ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                      : Icon(Icons.search_rounded, color: _primary, size: 26),
                ),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 8),
        Text('Ingresa el código de 8 caracteres que aparece en la reserva del cliente.',
            style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.4))),

        const SizedBox(height: 28),

        // Resultado
        if (_errorMsg != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text(_errorMsg!, style: GoogleFonts.sansita(color: Colors.red.shade700, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ),

        if (_reservaEncontrada != null) _buildReservaResultado(_reservaEncontrada!),
      ]),
    );
  }

  Widget _buildReservaResultado(Map<String, dynamic> r) {
    final estado = r['estado'] ?? 'Pendiente';
    final puedeConfirmar = estado == 'EsperandoValidacion' || estado == 'Pendiente';
    final yaEscaneado = _escaneados.any((e) => e['_id'] == r['_id']);

    Color estadoColor = _statusColor(estado);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resultado', style: GoogleFonts.sansita(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
      const SizedBox(height: 12),

      // Tarjeta de reserva
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Estado badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_estadoLabel(estado), style: GoogleFonts.sansita(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.person_rounded, 'Titular', r['usuario']?['nombre'] ?? '—'),
          _divider(),
          _infoRow(Icons.sports_rounded, 'Servicio', r['servicio']?['nombre'] ?? '—'),
          _divider(),
          _infoRow(Icons.calendar_today_rounded, 'Fecha', r['fecha'] ?? '—'),
          _divider(),
          _infoRow(Icons.access_time_rounded, 'Hora', r['hora'] ?? '—'),
          _divider(),
          _infoRow(Icons.tag_rounded, 'Código', r['codigoReserva'] ?? '—'),

          const SizedBox(height: 20),

          if (yaEscaneado)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
                const SizedBox(width: 10),
                Text('Ya validado en esta sesión', style: GoogleFonts.sansita(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ]),
            )
          else if (puedeConfirmar)
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _confirmarReserva(r['_id']),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text('Confirmar asistencia', style: GoogleFonts.sansita(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ))
          else if (estado == 'Confirmada')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                Expanded(child: Text('Esta reserva ya está confirmada. Verifica que sea el día y hora correctos.',
                    style: GoogleFonts.sansita(color: Colors.blue.shade700, fontSize: 13))),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.block_rounded, color: Colors.red.shade500),
                const SizedBox(width: 10),
                Text('Reserva en estado: ${_estadoLabel(estado)}', style: GoogleFonts.sansita(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              ]),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildListaTab() {
    if (_escaneados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.checklist_rounded, size: 72, color: _primary.withValues(alpha: 0.12)),
        const SizedBox(height: 16),
        Text('Lista de escaneados vacía', style: GoogleFonts.sansita(fontSize: 18, color: _primary.withValues(alpha: 0.35))),
        const SizedBox(height: 8),
        Text('Los clientes validados aparecerán aquí', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.25))),
      ]));
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_escaneados.length} validado(s)', style: GoogleFonts.sansita(fontSize: 14, color: _primary.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('¿Limpiar lista?', style: GoogleFonts.sansita(fontWeight: FontWeight.bold)),
                content: Text('Se eliminará la lista de esta sesión.', style: GoogleFonts.sansita()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.sansita())),
                  TextButton(onPressed: () { setState(() => _escaneados.clear()); Navigator.pop(ctx); },
                      child: Text('Limpiar', style: GoogleFonts.sansita(color: Colors.red))),
                ],
              ),
            ),
            icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
            label: Text('Limpiar', style: GoogleFonts.sansita(color: Colors.red.shade400, fontSize: 13)),
          ),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _escaneados.length,
        itemBuilder: (_, i) {
          final e = _escaneados[i];
          final validado = e['validadoEn'] != null ? DateTime.tryParse(e['validadoEn']) : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: Colors.green.shade600, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e['usuario']?['nombre'] ?? '—', style: GoogleFonts.sansita(fontSize: 15, fontWeight: FontWeight.bold, color: _primary)),
                Text('${e['fecha']} · ${e['hora']}', style: GoogleFonts.sansita(fontSize: 12, color: _primary.withValues(alpha: 0.5))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(e['codigoReserva'] ?? '', style: GoogleFonts.sansita(fontSize: 12, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.4), letterSpacing: 1)),
                if (validado != null)
                  Text('${validado.hour.toString().padLeft(2,'0')}:${validado.minute.toString().padLeft(2,'0')}',
                      style: GoogleFonts.sansita(fontSize: 11, color: Colors.green.shade600)),
              ]),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: _primary.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Text('$label:', style: GoogleFonts.sansita(fontSize: 13, color: _primary.withValues(alpha: 0.5))),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: GoogleFonts.sansita(fontSize: 13, fontWeight: FontWeight.bold, color: _primary), textAlign: TextAlign.end)),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1, color: _primary.withValues(alpha: 0.06));

  Color _statusColor(String estado) {
    switch (estado) {
      case 'Confirmada': return Colors.green.shade600;
      case 'EsperandoValidacion': return Colors.orange.shade600;
      case 'Cancelada': return Colors.red.shade500;
      case 'Terminada': return Colors.grey;
      default: return Colors.blue.shade600;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'EsperandoValidacion': return 'En espera de validación';
      case 'Confirmada': return 'Confirmada';
      case 'Cancelada': return 'Cancelada';
      case 'Terminada': return 'Terminada';
      default: return 'Pendiente';
    }
  }
}
