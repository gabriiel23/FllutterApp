import 'package:flutter/material.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_jugador.dart';
import 'package:flutterapp/features/reserves/presentation/pages/admin_reservas_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterapp/features/home_admin/presentation/pages/homeAdmin_page.dart';
import 'package:flutterapp/features/comunity/presentation/pages/comunity_page.dart';
import 'package:flutterapp/features/home/presentation/pages/home_page.dart';
import 'package:flutterapp/features/espacios_deportivos/pages/espacios_page.dart';
import 'package:flutterapp/features/espacios_deportivos/pages/espacios_admin.page.dart';
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
      // Ajustar índice actual si está fuera de rango al cambiar de rol
      if (_userRol == 'administrador' && _currentIndex > 3) {
        _currentIndex = 0;
      }
    });
  }

  List<Widget> get _pages {
    if (_userRol == 'administrador') {
      return [
        HomeAdminPage(),
        const AdminReservasPage(),
        ListaEspaciosAdminDeportivosPage(),
        ProfilePage(),
      ];
    } else if (_userRol == 'superadmin') {
      return [
        Home(),
        Groups(),
        ListaEspaciosAdminDeportivosPage(),
        const AdminReservasPage(),
        ProfilePage(),
      ];
    } else {
      // jugador
      return [
        Home(),
        Groups(),
        ListaEspaciosDeportivosPage(),
        Reserves_user(),
        ProfilePage(),
      ];
    }
  }

  List<String> get _labels {
    if (_userRol == 'administrador') {
      return ['Panel', 'Reservas', 'Mi Espacio', 'Perfil'];
    }
    return ['Inicio', 'Comunidad', '', 'Tus reservas', 'Perfil'];
  }

  List<IconData> get _icons {
    if (_userRol == 'administrador') {
      return [Icons.dashboard_rounded, Icons.calendar_month_rounded, Icons.sports_soccer_rounded, Icons.person_pin_rounded];
    }
    return [
      Icons.home,
      Icons.group,
      Icons.location_on, // Icono del botón flotante
      Icons.history_outlined,
      Icons.person_pin,
    ];
  }

  void _onItemTapped(int index) {
    if (_userRol != 'administrador' && index == 2) return; // Ignorar clic en espacio de FAB
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
            decoration: const BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.sports_soccer, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'CanchAPP SuperAdmin',
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Panel de Control'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/homeAdmin'); // Navegar a HomeAdmin como vista separada
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_soccer),
            title: const Text('Espacios Deportivos'),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reservas'),
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Gestión de Usuarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/gestionarUsuarios');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              // Aquí podrías redirigir al login
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdministrador = _userRol == 'administrador';
    
    return Scaffold(
      drawer: _userRol == 'superadmin' ? _buildDrawer() : null, // Solo SuperAdmin ve el Drawer
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: isAdministrador
          ? null // No mostrar FAB para el administrador
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              backgroundColor: Colors.green,
              shape: const CircleBorder(),
              child: const Icon(Icons.location_on, color: Colors.white, size: 24),
            ),
      floatingActionButtonLocation: isAdministrador ? null : FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomAppBar(
          shape: isAdministrador ? null : const CircularNotchedRectangle(),
          notchMargin: isAdministrador ? 0 : 8.0,
          color: const Color(0xFF19382F),
          elevation: 10,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_pages.length, (index) {
                  if (!isAdministrador && index == 2) {
                    return const SizedBox(width: 48); // Espacio vacío para el FAB
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
