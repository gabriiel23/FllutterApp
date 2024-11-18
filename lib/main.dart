import 'package:flutter/material.dart';
import 'screens/third.dart';
import 'screens/second.dart';
import 'screens/home.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: "/",
      routes: {
        "/": (context) => const Home(),
        "/home": (context) => const Home(),
        "/second": (context) => const Second(),
        "/third": (context) => const Third(),
      },

    ); // MaterialApp
  }
}
