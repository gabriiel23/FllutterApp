import 'package:flutter/material.dart';
import 'screens/screens.dart';
import 'screens/navigationBar.dart';

import 'package:flutterapp/presentation/routes/app_routes.dart';
import 'package:flutterapp/presentation/routes/routes.dart';
import 'package:provider/provider.dart';  
import 'theme/theme_provider.dart'; 

//void main() => runApp(const MyApp());


// Punto de entrada principal de la aplicación.
void main() => runApp(
  ChangeNotifierProvider(
    // Crea una instancia de ThemeProvider para manejar el estado del tema.
    create: (context) => ThemeProvider(),
    child: const MyApp(), // MyApp será el widget principal de la aplicación.
  ),
);

// Clase principal de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor con clave para manejar el estado.

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

/*

 backgroundColor: Colors.blue.shade700, // Fondo azul para la barra superior.
        foregroundColor: Colors.white, // Color de texto en la barra superior.
        titleTextStyle: TextStyle(
          fontSize: 20, // Tamaño del texto del título.
          fontWeight: FontWeight.bold, // Texto en negrita.
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.black87, fontSize: 16), // Estilo de texto principal.
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14), // Estilo de texto del cuerpo.
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700, // Color del botón elevado.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bordes redondeados.
          ),
        ),
      ),
    );

    // Define el tema oscuro de la aplicación.
    final darkTheme = ThemeData(
      brightness: Brightness.dark, // Configuración de tema oscuro.
      primarySwatch: Colors.blue, // Color primario predeterminado.
      scaffoldBackgroundColor: Colors.black87, // Fondo oscuro para las pantallas.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900, // Fondo gris oscuro para la barra superior.
        foregroundColor: Colors.white, // Color de texto en la barra superior.
        titleTextStyle: TextStyle(
          fontSize: 20, // Tamaño del texto del título.
          fontWeight: FontWeight.bold, // Texto en negrita.
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: Colors.white70, fontSize: 16), // Estilo de texto principal.
        bodyMedium: TextStyle(color: Colors.white54, fontSize: 14), // Estilo de texto del cuerpo.
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade300, // Color del botón elevado.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bordes redondeados.
          ),
        ),
      ),
    );

    // Configura y retorna la aplicación MaterialApp.
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Elimina la etiqueta de modo debug.
      title: 'Gestión de espacios deportivos', // Título de la aplicación.
      theme: lightTheme, // Tema predeterminado (claro).
      darkTheme: darkTheme, // Tema alternativo (oscuro).
      themeMode: themeProvider.themeMode, // Cambia dinámicamente entre temas según el estado.
      initialRoute: Routes.initialRoute, // Ruta inicial al iniciar la aplicación.
      routes: appRoutes, // Mapa de rutas definido en appRoutes.
    );

*/
