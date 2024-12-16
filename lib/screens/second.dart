import 'package:flutter/material.dart';

class Second extends StatelessWidget {
  const Second({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus Reservas"),
        backgroundColor: const Color.fromARGB(255, 29, 84, 26),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Resumen de Reservas",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 29, 84, 26),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Consulta y administra tus reservas de manera rápida y sencilla.",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Fecha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 29, 84, 26),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Hora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 29, 84, 26),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Espacio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 29, 84, 26),
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(Text('12/12/2024')),
                      DataCell(Text('10:00 AM')),
                      DataCell(Text('Cancha 1')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('13/12/2024')),
                      DataCell(Text('4:00 PM')),
                      DataCell(Text('Cancha 2')),
                    ]),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/home");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 29, 84, 26),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              child: Text(
                "Regresar al Inicio",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
