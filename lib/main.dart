import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/app_routes.dart';
import 'package:flutterapp/core/routes/routes.dart';
import 'package:provider/provider.dart';  
import 'theme/theme_provider.dart'; 
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

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