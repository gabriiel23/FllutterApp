import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // Índice actual seleccionado
  final ValueChanged<int> onTap; // Función callback al tocar un elemento

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // Índice seleccionado
      onTap: onTap, // Callback para manejar los toques
      selectedItemColor: Colors.green.shade800, // Color del elemento seleccionado
      unselectedItemColor: Colors.grey, // Color de los elementos no seleccionados
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
    );
  }
}
