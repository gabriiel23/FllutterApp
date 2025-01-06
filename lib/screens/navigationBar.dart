import 'package:flutter/material.dart';
import 'screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const Cancha(),
    const Calendar(),
    const Reserves(),
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
        color: Colors.black, // Fondo negro
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Espaciado vertical
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              final icons = [
                Icons.home,
                Icons.shopping_cart,
                Icons.favorite,
                Icons.person,
              ];
              return IconButton(
                icon: Icon(
                  icons[index],
                  size: 26, // Tamaño del ícono
                  color: _currentIndex == index ? Colors.white : Colors.grey,
                ),
                onPressed: () => _onItemTapped(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}
