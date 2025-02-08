import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/presentation/routes/routes.dart';

class NewReservePage extends StatefulWidget {
  @override
  _NewReservePageState createState() => _NewReservePageState();
}

class _NewReservePageState extends State<NewReservePage> {
  int _currentStep = 0;
  TextEditingController _tituloController = TextEditingController();
  TextEditingController _descripcionController = TextEditingController();
  String _selectedCancha = 'Cancha 1';
  DateTime? _selectedDate;  // Ahora es nullable
  TimeOfDay? _selectedTime;  // Cambiado para que sea nullable
  
  // Mapa de fechas a horas disponibles (ejemplo)
  Map<DateTime, List<TimeOfDay>> availableHours = {
    DateTime(2025, 1, 14): [TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 16, minute: 0)],
    DateTime(2025, 1, 15): [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 15, minute: 0)],
    DateTime(2025, 1, 16): [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 12, minute: 0)],
    // Agregar más fechas y horas disponibles
  };

  // Lista de horas disponibles para la fecha seleccionada
  List<TimeOfDay> _availableTimes = [];

  @override
  void initState() {
    super.initState();
  }

  void _updateAvailableTimes() {
    // Obtener las horas disponibles para la fecha seleccionada
    setState(() {
      _availableTimes = _selectedDate != null ? availableHours[_selectedDate!] ?? [] : [];
      // Si no hay horas disponibles, establecemos _selectedTime a null
      if (_availableTimes.isEmpty) {
        _selectedTime = null;
      } else {
        // Si hay horas disponibles, asignar la primera hora como valor por defecto
        _selectedTime ??= _availableTimes.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Nueva Reserva", style: GoogleFonts.sansita(color: Colors.white)),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rellena todos los campos requeridos para continuar con el pago de la reserva. ",
              style: GoogleFonts.sansita(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 1) {
                    setState(() {
                      _currentStep++;
                    });
                  } 
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep--;
                    });
                  }
                },
                steps: [
                  Step(
                    title: Text("Reserva", style: GoogleFonts.sansita(color: Color(0xFF19382F))),
                    content: Column(
                      children: [
                        TextField(
                          controller: _tituloController,
                          decoration: InputDecoration(
                            labelText: "Título de la reserva",
                            labelStyle: GoogleFonts.sansita(color: Color(0xFF19382F)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: "Descripción",
                            labelStyle: GoogleFonts.sansita(color: Color(0xFF19382F)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedCancha,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCancha = newValue!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Selecciona la Cancha',
                            labelStyle: GoogleFonts.sansita(color: Color(0xFF19382F)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                          ),
                          items: <String>['Cancha 1', 'Cancha 2', 'Cancha 3']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: GoogleFonts.sansita(color: Color(0xFF19382F))),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 15),
                        // El campo de fecha ahora no tiene un valor predeterminado visible
                        TextField(
                          controller: TextEditingController(text: _selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : ''),
                          decoration: InputDecoration(
                            labelText: "Fecha",
                            labelStyle: GoogleFonts.sansita(color: Color(0xFF19382F)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF19382F)),
                            ),
                          ),
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                // Actualizamos las horas disponibles al cambiar la fecha
                                _updateAvailableTimes();
                              });
                            }
                          },
                        ),
                        SizedBox(height: 15),
                        // Mostrar el Dropdown de horas solo si se ha seleccionado una fecha
                        _selectedDate != null
                            ? _availableTimes.isNotEmpty
                                ? DropdownButtonFormField<TimeOfDay>(
                                    value: _selectedTime,
                                    onChanged: (TimeOfDay? newTime) {
                                      setState(() {
                                        _selectedTime = newTime;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Selecciona la hora',
                                      labelStyle: GoogleFonts.sansita(color: Color(0xFF19382F)),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF19382F)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF19382F)),
                                      ),
                                    ),
                                    items: _availableTimes.map<DropdownMenuItem<TimeOfDay>>((TimeOfDay value) {
                                      return DropdownMenuItem<TimeOfDay>(
                                        value: value,
                                        child: Text(
                                          value.format(context),
                                          style: GoogleFonts.sansita(color: Color(0xFF19382F)),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Text(
                                    "No hay horas disponibles para esta fecha.",
                                    style: GoogleFonts.sansita(color: Colors.red),
                                  )
                            : Container(), // No mostrar nada si no hay fecha seleccionada
                      ],
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  ),
                  Step(
                    title: Text("Pago", style: GoogleFonts.sansita(color: Color(0xFF19382F))),
                    content: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.payment);

                        },
                        style: ElevatedButton.styleFrom(
                          textStyle: GoogleFonts.sansita(),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        ),
                        child: Text("Continuar con el pago"),
                      ),
                    ),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  ),
                ],
                type: StepperType.horizontal,
                elevation: 0,
                onStepTapped: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
