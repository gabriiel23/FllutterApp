import 'package:flutter/material.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_jugador.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/features/home_admin/presentation/pages/homeAdmin_page.dart';
import 'package:flutterapp/features/comunity/presentation/pages/groups_page.dart';
import 'package:flutterapp/features/home/presentation/pages/home_page.dart';
import 'package:flutterapp/features/espacios_deportivos/pages/espacios_page.dart';
import 'package:flutterapp/features/espacios_deportivos/pages/espacios_admin.page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _userRol;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRol = prefs.getString('userRol') ?? 'jugador';
    });
  }

  List<Widget> _buildPages() {
    return [
      _userRol == 'dueño' ? HomeAdminPage() : Home(),
      Groups(),
      _userRol == 'dueño' ? ListaEspaciosAdminDeportivosPage() : ListaEspaciosDeportivosPage(),
      _userRol == 'dueño' ? Reserves() : Reserves_user(),
      ProfilePage(),
    ];
  }

  final List<String> _labels = [
    'Inicio',
    'Comunidad',
    '', // Espacio para el FAB
    'Tus reservas',
    'Perfil'
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.group,
    Icons.location_on, // Icono del botón flotante
    Icons.history_outlined,
    Icons.person_pin,
  ];

  void _onItemTapped(int index) {
    if (index == 2) return; // Ignorar la selección del botón flotante
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sports_soccer, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'CanchAPP Admin',
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Panel de Control'),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.sports_soccer),
            title: Text('Espacios Deportivos'),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Reservas'),
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Cerrar Sesión'),
            onTap: () {
              // Aquí puedes agregar la funcionalidad para cerrar sesión
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _userRol == 'dueño' ? _buildDrawer() : null, // Drawer solo para dueños
      body: IndexedStack(
        index: _currentIndex,
        children: _buildPages(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.location_on, color: Colors.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: const Color(0xFF19382F),
          elevation: 10,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) {
                    return const SizedBox(width: 48); // Espacio para el FAB
                  }
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icons[index],
                          size: 24,
                          color: _currentIndex == index ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            color: _currentIndex == index ? Colors.white : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
