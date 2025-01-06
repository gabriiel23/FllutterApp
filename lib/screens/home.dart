import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/theme/theme_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<String> _routes = [
    Routes.home, // Home
    Routes.locals, // Locales
    Routes.reserve, // Reservas
    Routes.events, // Eventos
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CanchAPP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print("Buscar");
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'Perfil':
                  Navigator.pushNamed(context, Routes.profile);
                  break;
                case 'Login':
                  Navigator.pushNamed(context, Routes.login);
                  break;
                case 'Configuración':
                  Navigator.pushNamed(context, Routes.settings);
                  break;
                case 'Registro':
                  Navigator.pushNamed(context, Routes.registration);
                  break;
                case 'Cerrar sesión':
                  Navigator.pushReplacementNamed(context, Routes.logout);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Perfil', 'Login', 'Configuración', 'Registro', 'Cerrar sesión'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Título principal (comentado para posible uso futuro)
            /*const Text(
              "Bienvenido a CanchAPP",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),*/
            const SizedBox(height: 20),
            // Imagen destacada (comentado para posible uso futuro)
            /*ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/fubol.gif',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),*/
            const SizedBox(height: 20),
            // Carrusel de publicidad
            const Text(
              "Propaganda",
              style: TextStyle(
                fontSize: 20,
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
                        'https://via.placeholder.com/200x150',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      width: 200,
                      child: Image.network(
                        'https://via.placeholder.com/200x150',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      width: 200,
                      child: Image.network(
                        'https://via.placeholder.com/200x150',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Promociones y ofertas
            const Text(
              "Promociones y Ofertas",
              style: TextStyle(
                fontSize: 20,
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
                          'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "20% de descuento",
                          textAlign: TextAlign.center,
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
                          'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Promoción 2x1",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Opiniones de Usuarios
            const Text(
              "Opiniones de Usuarios",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: const Text("Juan Pérez"),
              subtitle: const Text("Excelente servicio, rápido y confiable."),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: const Text("Ana Gómez"),
              subtitle: const Text("Reservar canchas nunca fue tan fácil."),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
        ],
      ),
    );
  }
}
