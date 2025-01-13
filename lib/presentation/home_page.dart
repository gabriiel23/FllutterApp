import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutterapp/presentation/routes/routes.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<String> _routes = [
    Routes.home, // Home 
    Routes.reserves, // Reservas
    Routes.events, // Eventos
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pushNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor principal con fondo
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF19382F),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y logo
                  Row(
                    children: [
                      Text(
                        "CanchAPP",
                        style: GoogleFonts.sansita(
                          fontSize: 76,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 18.0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 68,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Barra de búsqueda y botón de menú (independiente)
                  Row(
                    children: [
                      // Barra de búsqueda
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.black),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: TextField(
                                  style: GoogleFonts.sansita(color: Colors.black),
                                  decoration: const InputDecoration(
                                    hintText: "Busca tu cancha...",
                                    hintStyle: TextStyle(color: Colors.black),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Botón de menú desplegable
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          switch (value) {
                            case 'Login':
                              Navigator.pushNamed(context, Routes.login);
                              break;
                            case 'Registro':
                              Navigator.pushNamed(context, Routes.registration);
                              break;
                            case 'Configuración':
                              Navigator.pushNamed(context, Routes.settings);
                              break;
                            case 'Cerrar sesión':
                              Navigator.pushReplacementNamed(context, Routes.logout);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return {'Login', 'Registro', 'Configuración', 'Cerrar sesión'}
                              .map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(
                                choice,
                                style: GoogleFonts.sansita(),
                              ),
                            );
                          }).toList();
                        },
                        icon: const Icon(
                          Icons.menu_sharp,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Carrusel de publicidad
            Text(
              "- Propaganda",
              style: GoogleFonts.sansita(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Card(
                    child: Container(
                      width: 200,
                      child: Image.network(
                        'https://www.shutterstock.com/image-photo/soccer-football-background-ball-pair-600nw-2025816362.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      width: 200,
                      child: Image.network(
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRnReWxPokNADhge6s31jycM2F4h4dxJB8S6w&s',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      width: 200,
                      child: Image.network(
                        'https://www.canchasfutboleros.com/uploads/1/3/7/3/137335804/canchas-sinteticas-futboleros-5-centro_orig.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Promociones y ofertas
            Text(
              "- Promociones y Ofertas",
              style: GoogleFonts.sansita(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          'https://m.media-amazon.com/images/I/71CyHz0JdOL._AC_UF894,1000_QL80_.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "20% de descuento",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sansita(),
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          'https://m.media-amazon.com/images/I/71CyHz0JdOL._AC_UF894,1000_QL80_.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Promoción 2x1",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sansita(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Opiniones de Usuarios
            Text(
              "- Opiniones de Usuarios",
              style: GoogleFonts.sansita(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: Text("Juan Pérez", style: GoogleFonts.sansita()),
              subtitle: Text("Excelente servicio, rápido y confiable.", style: GoogleFonts.sansita()),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text("Ana Gómez", style: GoogleFonts.sansita()),
              subtitle: Text("Reservar canchas nunca fue tan fácil.", style: GoogleFonts.sansita()),
            ),
          ],
        ),
      ),
    );
  }
}
