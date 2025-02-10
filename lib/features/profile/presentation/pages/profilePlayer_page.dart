import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePlayerPage extends StatefulWidget {
  @override
  _ProfilePlayerPageState createState() => _ProfilePlayerPageState();
}

class _ProfilePlayerPageState extends State<ProfilePlayerPage> {
  String? selectedRole;
  double height = 170;
  int age = 18;
  Map<String, int> attributes = {
    'Tiro': 5,
    'Regate': 5,
    'Pase': 5,
    'Ritmo': 5,
    'Defensa': 5,
    'Físico': 5,
    'Reflejos': 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil de Jugador',
          style: GoogleFonts.sansita(color: Colors.white),
        ),
        backgroundColor: Color(0xFF19382F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSeK0gW1HYfQOp7FPzueC8sufR7nv0Bi2WejZyhEbIO9gEuBKtoEbiPs_oTOivMRzu4Jjs&usqp=CAU',
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text('Selecciona tu posición:', style: GoogleFonts.sansita(fontSize: 18)),
            ),
            Center(
              child: DropdownButton<String>(
                value: selectedRole,
                hint: Text('Elige una opción             '),
                items: ['Portero', 'Jugador'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
            ),
            if (selectedRole != null) buildForm(),
            SizedBox(height: 20),
            if (selectedRole != null)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Guardar perfil
                  },
                  child: Text('Guardar Perfil', style: GoogleFonts.sansita(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF19382F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildForm() {
    List<String> attributesList = selectedRole == 'Portero'
        ? ['Tiro', 'Reflejos', 'Pase', 'Ritmo', 'Físico']
        : ['Tiro', 'Regate', 'Pase', 'Ritmo', 'Defensa', 'Físico'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Estatura (cm): ${height.toInt()}', style: GoogleFonts.sansita(fontSize: 18)),
        Slider(
          value: height,
          min: 140,
          max: 210,
          divisions: 60,
          label: height.toInt().toString(),
          onChanged: (value) {
            setState(() {
              height = value;
            });
          },
        ),
        Text('Edad: $age', style: GoogleFonts.sansita(fontSize: 18)),
        Slider(
          value: age.toDouble(),
          min: 10,
          max: 70,
          divisions: 40,
          label: age.toString(),
          onChanged: (value) {
            setState(() {
              age = value.toInt();
            });
          },
        ),
        ...attributesList.map((attr) => buildStarRating(attr)).toList(),
      ],
    );
  }

  Widget buildStarRating(String attribute) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$attribute: ${attributes[attribute]}', style: GoogleFonts.sansita(fontSize: 18)),
        Row(
          children: List.generate(10, (index) {
            return IconButton(
              icon: Icon(
                index < attributes[attribute]! ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.green,
              ),
              onPressed: () {
                setState(() {
                  attributes[attribute] = index + 1;
                });
              },
            );
          }),
        ),
      ],
    );
  }
}
