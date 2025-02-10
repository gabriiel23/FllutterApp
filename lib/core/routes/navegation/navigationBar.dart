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
    Canchas(),
    Groups(),
    Reserves(),
    ProfilePage(),
  ];

  final List<String> _labels = [
    'Inicio',
    'Canchas',
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
        children: _pages,
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
