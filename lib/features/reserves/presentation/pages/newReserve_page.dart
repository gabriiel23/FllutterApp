import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutterapp/config.dart';

class NewReservePage extends StatefulWidget {
  @override
  _NewReservePageState createState() => _NewReservePageState();
}

class _NewReservePageState extends State<NewReservePage> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _servicioId;
  String? _espacioId;
  List<TimeOfDay> allHours = [];
  Map<DateTime, List<TimeOfDay>> bookedHours = {};

  final Color _primaryDeep = const Color(0xFF19382F);

  @override
  void initState() {
    super.initState();
    _loadServicioId().then((_) => _fetchAvailableHours());
  }

  Future<void> _loadServicioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _servicioId = prefs.getString('servicio_id');
      _espacioId = prefs.getString('espacio_id');
    });
  }

  Future<void> _fetchAvailableHours() async {
    if (_servicioId == null) return;
    var response = await http.get(
      Uri.parse('${Config.baseUrl}/api/$_servicioId/horarios'),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      List<dynamic> horarios = jsonDecode(response.body);
      allHours.clear();
      for (var horario in horarios) {
        int startHour = int.parse(horario['inicio'].split(':')[0]);
        int startMinute = int.parse(horario['inicio'].split(':')[1]);
        int endHour = int.parse(horario['fin'].split(':')[0]);
        for (int hour = startHour; hour < endHour; hour++) {
          allHours.add(TimeOfDay(hour: hour, minute: startMinute));
        }
      }
      await _fetchBookedHours();
      if (_selectedDate != null) {
        DateTime selectedDay = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        List<TimeOfDay> reservedTimes = bookedHours[selectedDay] ?? [];
        allHours.removeWhere((hour) => reservedTimes.contains(hour));
      }
      setState(() {});
    }
  }

  Future<void> _fetchBookedHours() async {
    if (_servicioId == null) return;
    var response = await http.get(
      Uri.parse('${Config.baseUrl}/api/reservas/servicio/$_servicioId'),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      List<dynamic> reservas = jsonDecode(response.body);
      setState(() {
        bookedHours.clear();
        for (var reserva in reservas) {
          DateTime fechaReserva = DateTime.parse(reserva['fecha']);
          TimeOfDay horaReserva = TimeOfDay(
            hour: int.parse(reserva['hora'].split(':')[0]),
            minute: int.parse(reserva['hora'].split(':')[1]),
          );
          bookedHours.putIfAbsent(fechaReserva, () => []).add(horaReserva);
        }
      });
    }
  }

  Future<void> _confirmarReserva() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _servicioId == null ||
        _espacioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Falta seleccionar fecha, hora o espacio.",
                    style: GoogleFonts.sansita())),
      );
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioId = prefs.getString('userId');
    if (usuarioId == null) return;

    String formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    String formattedTime =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

    var response = await http.post(
      Uri.parse('${Config.baseUrl}/api/reservas/crear'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usuario": usuarioId,
        "servicio": _servicioId!,
        "espacio": _espacioId!,
        "fecha": formattedDate,
        "hora": formattedTime,
        "estado": "Pendiente",
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pushNamed(context, Routes.payment);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error al hacer la reserva.",
                style: GoogleFonts.sansita())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(child: _buildStepContent()),
          _buildBottomBar(),
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
              // Fila 1: Botón volver
              Row(
                children: [
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
                    child: Icon(Icons.calendar_month_rounded,
                        size: 24, color: _primaryDeep),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nueva reserva',
                    style: GoogleFonts.sansita(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _primaryDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fila 3: Descripción
              Text(
                'Completa los pasos para confirmar tu reserva',
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

  // ── STEP INDICATOR ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Fecha', 'Hora', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Línea conectora
            final stepIndex = i ~/ 2;
            final isCompleted = _currentStep > stepIndex;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: isCompleted
                    ? _primaryDeep
                    : _primaryDeep.withValues(alpha: 0.12),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = _currentStep == stepIndex;
          final isCompleted = _currentStep > stepIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 38 : 32,
            height: isActive ? 38 : 32,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? _primaryDeep
                  : _primaryDeep.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: _primaryDeep.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : Text(
                      '${stepIndex + 1}',
                      style: GoogleFonts.sansita(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : _primaryDeep.withValues(alpha: 0.4),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ── CONTENIDO DEL STEP ────────────────────────────────────────────────────
  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.all(24),
        child: _currentStep == 0
            ? _buildStepFecha()
            : _currentStep == 1
                ? _buildStepHora()
                : _buildStepConfirmacion(),
      ),
    );
  }

  // ── STEP 1: FECHA ─────────────────────────────────────────────────────────
  Widget _buildStepFecha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona el día',
          style: GoogleFonts.sansita(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _primaryDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige la fecha en la que quieres jugar',
          style: GoogleFonts.sansita(
              fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                  color: _primaryDeep.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: TableCalendar(
            locale: 'es_ES',
            focusedDay: _selectedDate ?? DateTime.now(),
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, _) {
              setState(() => _selectedDate = selectedDay);
              _fetchAvailableHours();
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: _primaryDeep,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: _primaryDeep.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.sansita(
                  color: _primaryDeep, fontWeight: FontWeight.bold),
              selectedTextStyle:
                  GoogleFonts.sansita(color: Colors.white),
              defaultTextStyle: GoogleFonts.sansita(color: _primaryDeep),
              weekendTextStyle: GoogleFonts.sansita(
                  color: _primaryDeep.withValues(alpha: 0.5)),
              outsideTextStyle: GoogleFonts.sansita(
                  color: _primaryDeep.withValues(alpha: 0.2)),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.sansita(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryDeep,
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: _primaryDeep),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: _primaryDeep),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.sansita(
                  fontSize: 13,
                  color: _primaryDeep.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600),
              weekendStyle: GoogleFonts.sansita(
                  fontSize: 13,
                  color: _primaryDeep.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryDeep.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: _primaryDeep, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Fecha seleccionada: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: GoogleFonts.sansita(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── STEP 2: HORA ──────────────────────────────────────────────────────────
  Widget _buildStepHora() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona la hora',
          style: GoogleFonts.sansita(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primaryDeep),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige un horario disponible para tu reserva',
          style: GoogleFonts.sansita(
              fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 20),
        if (_selectedDate == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Text('Primero selecciona una fecha',
                    style: GoogleFonts.sansita(
                        color: Colors.orange.shade800, fontSize: 14)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: allHours.length,
            itemBuilder: (context, index) {
              final hour = allHours[index];
              final isBooked = bookedHours[_selectedDate]?.any((b) =>
                      b.hour == hour.hour && b.minute == hour.minute) ??
                  false;
              final isSelected = _selectedTime == hour && !isBooked;
              final label =
                  "${hour.hour.toString().padLeft(2, '0')}:${hour.minute.toString().padLeft(2, '0')}";

              return GestureDetector(
                onTap: isBooked
                    ? null
                    : () => setState(() => _selectedTime = hour),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isBooked
                        ? Colors.red.withValues(alpha: 0.07)
                        : isSelected
                            ? _primaryDeep
                            : _primaryDeep.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBooked
                          ? Colors.red.withValues(alpha: 0.2)
                          : isSelected
                              ? _primaryDeep
                              : _primaryDeep.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.sansita(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isBooked
                            ? Colors.red.shade300
                            : isSelected
                                ? Colors.white
                                : _primaryDeep.withValues(alpha: 0.7),
                        decoration: isBooked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        if (allHours.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLeyenda(_primaryDeep, 'Disponible'),
              const SizedBox(width: 16),
              _buildLeyenda(Colors.red.shade200, 'Reservado'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLeyenda(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.sansita(
                fontSize: 12,
                color: _primaryDeep.withValues(alpha: 0.5))),
      ],
    );
  }

  // ── STEP 3: CONFIRMACIÓN ──────────────────────────────────────────────────
  Widget _buildStepConfirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirma tu reserva',
          style: GoogleFonts.sansita(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primaryDeep),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa los detalles antes de proceder al pago',
          style: GoogleFonts.sansita(
              fontSize: 14, color: _primaryDeep.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryDeep.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _buildConfirmRow(
                Icons.calendar_today_rounded,
                'Fecha',
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : '—',
              ),
              const SizedBox(height: 16),
              Divider(color: _primaryDeep.withValues(alpha: 0.08)),
              const SizedBox(height: 16),
              _buildConfirmRow(
                Icons.access_time_rounded,
                'Hora',
                _selectedTime != null
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : '—',
              ),
              const SizedBox(height: 16),
              Divider(color: _primaryDeep.withValues(alpha: 0.08)),
              const SizedBox(height: 16),
              _buildConfirmRow(
                Icons.info_outline_rounded,
                'Estado',
                'Pendiente de pago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primaryDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: _primaryDeep),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.sansita(
                    fontSize: 12,
                    color: _primaryDeep.withValues(alpha: 0.45))),
            Text(value,
                style: GoogleFonts.sansita(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryDeep)),
          ],
        ),
      ],
    );
  }

  // ── BARRA INFERIOR ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    final canContinue = _currentStep == 0
        ? _selectedDate != null
        : _currentStep == 1
            ? _selectedTime != null
            : true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: _primaryDeep.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Material(
                color: _primaryDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => setState(() => _currentStep--),
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Icons.arrow_back_rounded,
                        color: _primaryDeep, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: canContinue
                      ? () {
                          if (isLastStep) {
                            _confirmarReserva();
                          } else {
                            setState(() => _currentStep++);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDeep,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _primaryDeep.withValues(alpha: 0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    isLastStep
                        ? Icons.payment_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isLastStep ? 'Proceder al pago' : 'Continuar',
                    style: GoogleFonts.sansita(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
