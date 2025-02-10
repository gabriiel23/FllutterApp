import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart'; // Para el calendario
import 'package:flutterapp/core/routes/routes.dart';

class NewReservePage extends StatefulWidget {
  @override
  _NewReservePageState createState() => _NewReservePageState();
}

class _NewReservePageState extends State<NewReservePage> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Simulación de horarios reservados (esto normalmente vendría del backend)
  Map<DateTime, List<TimeOfDay>> bookedHours = {
    DateTime(2025, 2, 15): [
      TimeOfDay(hour: 10, minute: 0),
      TimeOfDay(hour: 14, minute: 0)
    ],
    DateTime(2025, 2, 16): [TimeOfDay(hour: 9, minute: 0)],
  };

  // Todas las horas posibles en un día
  final List<TimeOfDay> allHours =
      List.generate(16, (index) => TimeOfDay(hour: 8 + index, minute: 0));

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
              "Completa todos los pasos de la reserva para proceder con el pago de la misma.",
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
                  content: Column(
                    children: [
                      TableCalendar(
                        focusedDay: DateTime.now(),
                        firstDay: DateTime(2025, 1, 1),
                        lastDay: DateTime(2025, 12, 31),
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDate, day),
                        onDaySelected: (selectedDay, _) {
                          setState(() => _selectedDate = selectedDay);
                        },
                      ),
                      if (_selectedDate != null) ...[
                        SizedBox(height: 10),
                        Text(
                            "Seleccionaste: ${_selectedDate!.toLocal().toString().split(' ')[0]}")
                      ],
                    ],
                  ),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: Text("Selecciona la hora"),
                  content: Column(
                    children: _selectedDate == null
                        ? [Text("Por favor, selecciona un día primero.")]
                        : allHours.map((hour) {
                            bool isBooked =
                                bookedHours[_selectedDate]?.contains(hour) ??
                                    false;
                            return ListTile(
                              title: Text(hour.format(context),
                                  style: GoogleFonts.sansita()),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isBooked
                                        ? Icons.cancel
                                        : Icons.check_circle,
                                    color: isBooked ? Colors.red : Colors.green,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    isBooked ? "Ocupado" : "Libre",
                                    style: GoogleFonts.sansita(
                                      fontSize: 14,
                                      color:
                                          isBooked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: isBooked
                                  ? null
                                  : () => setState(() => _selectedTime = hour),
                              selected: _selectedTime == hour,
                            );
                          }).toList(),
                  ),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: Text("Confirmación y Pago"),
                  content: Column(
                    children: [
                      if (_selectedDate == null || _selectedTime == null)
                        Text("Por favor, selecciona fecha y hora primero.")
                      else ...[
                        Text(
                            "Fecha: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                            style: GoogleFonts.sansita(fontSize: 18)),
                        Text("Hora: ${_selectedTime!.format(context)}",
                            style: GoogleFonts.sansita(fontSize: 18)),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.payment);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF19382F),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
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
