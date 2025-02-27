import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      Home(),
      _userRol == 'dueño' ? ListaEspaciosAdminDeportivosPage() : ListaEspaciosDeportivosPage(),
      Groups(),
      Reserves(),
      ProfilePage(),
    ];
  }

  final List<String> _labels = [
    'Inicio',
    'Espacios',
    'Comunidad',
    'Tus reservas',
    'Perfil'
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.location_on,
    Icons.group,
    Icons.history_outlined,
    Icons.person_pin,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF19382F),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              return InkWell(
                onTap: () => _onItemTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[index],
                      size: 22,
                      color: _currentIndex == index ? Colors.white : Colors.grey,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        color: _currentIndex == index ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
