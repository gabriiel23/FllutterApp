import 'package:flutter/material.dart';
import 'screens/screens.dart';
import 'screens/navigationBar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CanchAPP',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MainScreen(), // Usa MainScreen como página principal
    );
  }
}
