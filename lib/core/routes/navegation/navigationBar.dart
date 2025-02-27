import 'package:flutter/material.dart';
import 'package:flutterapp/features/comunity/presentation/pages/groups_page.dart';
import 'package:flutterapp/features/home/presentation/pages/home_page.dart';
import 'package:flutterapp/features/canchas/presentation/pages/canchas_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Home(),
    Groups(),
    Canchas(),
    Reserves(),
    ProfilePage(),
  ];

  final List<String> _labels = [
    'Inicio',
    'Comunidad',
    '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
        mini: false, // ✅ Hace el FAB más pequeño
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
          notchMargin: 8.0, // ✅ Más espacio alrededor del FAB
          color: const Color(0xFF19382F),
          elevation: 10,
          child: SizedBox(
            height: 56, // ✅ Evita el overflow
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0), // ✅ Espacio extra
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
                          size: 24, // ✅ Tamaño más compacto
                          color: _currentIndex == index ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            color: _currentIndex == index ? Colors.white : Colors.grey,
                            fontSize: 11, // ✅ Fuente más pequeña
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
