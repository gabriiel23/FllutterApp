import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  
import 'theme/theme_provider.dart'; 

import 'screens/home.dart';
import 'screens/second.dart';
import 'screens/third.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el estado del tema desde el proveedor.
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Define los temas claro y oscuro.
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      theme: lightTheme,  // Tema claro.
      darkTheme: darkTheme,  // Tema oscuro.
      themeMode: themeProvider.themeMode,  // Cambia dinámicamente entre temas.
      initialRoute: "/",
      routes: {
        "/": (context) => const Home(),
        "/home": (context) => const Home(),
        "/second": (context) => const Second(),
        "/third": (context) => const Third(),
      },
    );
  }
}