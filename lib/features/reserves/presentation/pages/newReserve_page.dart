import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewReservePage extends StatefulWidget {
  @override
  _NewReservePageState createState() => _NewReservePageState();
}

class _NewReservePageState extends State<NewReservePage> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _servicioId;
  List<TimeOfDay> allHours = [];
  Map<DateTime, List<TimeOfDay>> bookedHours = {};

  @override
  void initState() {
    super.initState();
    _loadServicioId().then((_) {
      _fetchAvailableHours();
    });
  }

  Future<void> _loadServicioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _servicioId = prefs.getString('servicio_id');
    });
    print("ID del servicio en NewReservePage: $_servicioId");
  }

Future<void> _fetchAvailableHours() async {
  if (_servicioId == null) return;

  var response = await http.get(
    Uri.parse("http://localhost:3000/api/$_servicioId/horarios"),
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
        TimeOfDay currentHour = TimeOfDay(hour: hour, minute: startMinute);
        allHours.add(currentHour);
      }
    }

    // Obtener reservas existentes antes de filtrar
    await _fetchBookedHours();

    // Filtrar horarios reservados según la fecha seleccionada
    if (_selectedDate != null) {
      DateTime selectedDay = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      List<TimeOfDay> reservedTimes = bookedHours[selectedDay] ?? [];

      allHours.removeWhere((hour) => reservedTimes.contains(hour));
    }

    setState(() {}); // Asegura que la UI se actualice
    print("Horarios disponibles después de filtrar: $allHours");
  } else {
    print("Error al obtener horarios: ${response.body}");
  }
}

  Future<void> _fetchBookedHours() async {
    if (_servicioId == null) return;

    var response = await http.get(
      Uri.parse("http://localhost:3000/api/reservas/servicio/$_servicioId"),
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
      print("Horas reservadas: $bookedHours");
    } else {
      print("Error al obtener reservas: ${response.body}");
    }
  }

  Future<void> _confirmarReserva() async {
    if (_selectedDate == null || _selectedTime == null || _servicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Falta seleccionar fecha y hora.")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioId = prefs.getString('userId');

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se ha encontrado el ID del usuario.")),
      );
      return;
    }

    String formattedDate =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    String formattedTime =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

    Map<String, String> reservaData = {
      "usuario": usuarioId,
      "servicio": _servicioId!,
      "fecha": formattedDate,
      "hora": formattedTime,
      "estado": "Pendiente",
    };

    var response = await http.post(
      Uri.parse("http://localhost:3000/api/reservas/crear"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reservaData),
    );

    if (response.statusCode == 201) {
      print("Reserva confirmada: ${response.body}");
      Navigator.pushNamed(context, Routes.payment);
    } else {
      print("Error al reservar: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al hacer la reserva.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nueva Reserva",
            style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Completa todos los pasos de la reserva para proceder con el pago.",
              style: GoogleFonts.sansita(fontSize: 18, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: [
                Step(
                  title: Text("Selecciona el día"),
                  content: TableCalendar(
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2025, 1, 1),
                    lastDay: DateTime(2025, 12, 31),
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, _) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                      _fetchAvailableHours(); // Llamar a la función después de seleccionar la fecha
                    },
                  ),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: Text("Selecciona la hora"),
                  content: Column(
                    children: _selectedDate == null
                        ? [Text("Por favor, selecciona un día primero.")]
                        : allHours.map((hour) {
                            bool isBooked = bookedHours[_selectedDate]?.any(
                                    (booked) =>
                                        booked.hour == hour.hour &&
                                        booked.minute == hour.minute) ??
                                false;

                            return ListTile(
                              title: Text(
                                "${hour.hour.toString().padLeft(2, '0')}:${hour.minute.toString().padLeft(2, '0')}", // Formato 24h
                                style: GoogleFonts.sansita(
                                  color: isBooked ? Colors.red : Colors.black,
                                  fontWeight: isBooked
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              tileColor:
                                  isBooked ? Colors.red.withOpacity(0.2) : null,
                              onTap: isBooked
                                  ? null
                                  : () => setState(() => _selectedTime = hour),
                              selected: _selectedTime == hour && !isBooked,
                              enabled: !isBooked, // Evita que se seleccione
                            );
                          }).toList(),
                  ),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: Text("Confirmación y Pago"),
                  content: Column(
                    children: [
                      if (_selectedDate != null && _selectedTime != null) ...[
                        Text(
                            "Fecha: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                            style: GoogleFonts.sansita(fontSize: 18)),
                        Text("Hora: ${_selectedTime!.format(context)}",
                            style: GoogleFonts.sansita(fontSize: 18)),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _confirmarReserva,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF19382F),
                              foregroundColor: Colors.white),
                          child: Text("Proceder al pago"),
                        ),
                      ],
                    ],
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
