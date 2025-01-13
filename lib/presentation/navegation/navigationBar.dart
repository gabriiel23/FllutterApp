import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/groups_page.dart';
import 'package:flutterapp/presentation/home_page.dart';
import 'package:flutterapp/presentation/canchas_page.dart';
import 'package:flutterapp/presentation/reserves_page.dart';
import 'package:flutterapp/presentation/profile_page.dart';



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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final icons = [
                Icons.home,
                Icons.location_on,
                Icons.group,
                Icons.history_outlined,
                Icons.person_pin,
              ];
              return IconButton(
                icon: Icon(
                  icons[index],
                  size: 26,
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
