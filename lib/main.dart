import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/app_routes.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:provider/provider.dart';  
import 'theme/theme_provider.dart'; 

void main() => runApp(
  
  ChangeNotifierProvider(
    create: (context
    ) => ThemeProvider(),
    child: const MyApp(),
  ),
);

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
      initialRoute: Routes.initialRoute, // Define la ruta inicial
      routes: appRoutes, // Usa las rutas definidas en app_routes.dart
    );
  }
}