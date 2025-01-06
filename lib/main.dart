import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/routes/app_routes.dart';
import 'package:flutterapp/presentation/routes/routes.dart';
import 'package:provider/provider.dart';  
import 'theme/theme_provider.dart'; 

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
    // Define los temas claro y oscuro con estilos más personalizados.
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      ),
      // estilos de texto personalizados y configuraciones para botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black87,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.white70, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white54, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de espacios deportivos',
      theme: lightTheme,  // Tema claro.
      darkTheme: darkTheme,  // Tema oscuro.
      themeMode: themeProvider.themeMode,  // Cambia dinámicamente entre temas.
      initialRoute: Routes.initialRoute,
      routes: appRoutes,
    );
  }
}