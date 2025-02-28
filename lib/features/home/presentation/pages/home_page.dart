import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/core/routes/routes.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _selectedSection = "Noticias"; // Sección predeterminada

  void _changeSection(String section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
            left: 28.0, right: 28.0, bottom: 28.0, top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título y menú
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "👻  GhosTICS",
                  style: GoogleFonts.sansita(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'Login':
                        Navigator.pushNamed(context, Routes.login);
                        break;
                      case 'Registro':
                        Navigator.pushNamed(context, Routes.registration);
                        break;
                      case 'Configuración':
                        Navigator.pushNamed(context, Routes.settings);
                        break;
                      case 'Cerrar sesión':
                        Navigator.pushReplacementNamed(context, Routes.logout);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      'Login',
                      'Registro',
                      'Configuración',
                      'Cerrar sesión'
                    ].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice,
                          style: GoogleFonts.sansita(),
                        ),
                      );
                    }).toList();
                  },
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: const Icon(
                      Icons.menu_open_rounded,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            Text(
              "CanchAPP",
              style: GoogleFonts.sansita(
                fontSize: 88,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    offset: Offset(4.0, 4.0),
                    blurRadius: 30.0,
                    color: Color.fromARGB(255, 4, 189, 10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      "🥅  10000+",
                      style: GoogleFonts.sansita(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Espacios deportivos",
                      style: GoogleFonts.sansita(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  children: [
                    Text(
                      "🧍🏻‍♂ 200000+",
                      style: GoogleFonts.sansita(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Usuarios activos",
                      style: GoogleFonts.sansita(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Botones de selección de sección
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryButton("Noticias"),
                SizedBox(width: 20),
                _buildCategoryButton("Eventos"),
                SizedBox(width: 20),
                _buildCategoryButton("Reseñas"),
              ],
            ),

            const SizedBox(height: 20),

            // Contenido dinámico
            if (_selectedSection == "Noticias") _buildNoticias(),
            if (_selectedSection == "Eventos") _buildEventos(),
            if (_selectedSection == "Reseñas") _buildResenias(),
          ],
        ),
      ),
    );
  }

  // Método para construir los botones de selección
  Widget _buildCategoryButton(String label) {
    bool isSelected = _selectedSection == label;

    return GestureDetector(
      onTap: () => _changeSection(label),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19382F) : const Color(0xFF19382F),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == "Noticias"
                  ? Icons.newspaper
                  : label == "Eventos"
                      ? Icons.event
                      : Icons.reviews,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sección de Noticias
  Widget _buildNoticias() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF19382F),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      "❓ Novedades",
                      style: GoogleFonts.sansita(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7iPQkoJvHMKAoL1gygV7KDFGoAQ9Fc-q8AG4-GNgnX8XSfFuhVXObZMQD891BHGP0m_Y&usqp=CAU",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cancha El Campus Loja",
                            style: GoogleFonts.sansita(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "No se abrirá en feriado!",
                            style: GoogleFonts.sansita(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "El 28 de febrero y el 01 de marzo no se abrirán nuestras instalaciones.",
                  style: GoogleFonts.sansita(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Eventos
  Widget _buildEventos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF19382F),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      "🗓 Eventos",
                      style: GoogleFonts.sansita(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        "https://thumbs.dreamstime.com/b/ni%C3%B1os-que-entrenan-al-gimnasio-interior-futsal-del-f%C3%BAtbol-muchacho-joven-con-el-bal%C3%B3n-de-f%C3%BAtbol-80732309.jpg",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cancha El Fortín",
                            style: GoogleFonts.sansita(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Campeonato Fútbol Sala",
                            style: GoogleFonts.sansita(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Primer campeonato de futbol sala en nuestro espacio deportivo.",
                  style: GoogleFonts.sansita(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Reseñas
  Widget _buildResenias() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF19382F),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "📃  Opiniones de los usuarios",
            style: GoogleFonts.sansita(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
            ),
            title: Text("Juan Pérez",
                style: GoogleFonts.sansita(color: Colors.white)),
            subtitle: Text("Excelente servicio, rápido y confiable.",
                style: GoogleFonts.sansita(color: Colors.grey.shade400)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text("Rosa Gonzales",
                style: GoogleFonts.sansita(color: Colors.white)),
            subtitle: Text("Reservar en línea nunca fue tan fácil!.",
                style: GoogleFonts.sansita(color: Colors.grey.shade400)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
            ),
            title: Text("Juan Pérez",
                style: GoogleFonts.sansita(color: Colors.white)),
            subtitle: Text("Excelente servicio, rápido y confiable.",
                style: GoogleFonts.sansita(color: Colors.grey.shade400)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text("Rosa Gonzales",
                style: GoogleFonts.sansita(color: Colors.white)),
            subtitle: Text("Reservar en línea nunca fue tan fácil!.",
                style: GoogleFonts.sansita(color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}