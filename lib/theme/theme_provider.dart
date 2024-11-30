import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;  // Tema por defecto es claro.

  ThemeMode get themeMode => _themeMode;  // Obtiene el tema actual.

  // Método para alternar entre temas claro y oscuro
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();  // Notifica a los widgets para que se actualicen.
  }
}
