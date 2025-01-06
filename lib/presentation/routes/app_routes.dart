import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/locales_page.dart';
import 'package:flutterapp/presentation/login_page.dart';
import 'package:flutterapp/presentation/logout_pageage.dart';
import 'package:flutterapp/presentation/profile_page.dart';
import 'package:flutterapp/presentation/registration_page.dart';
import 'package:flutterapp/presentation/settings_page.dart';
import 'package:flutterapp/presentation/splash_page.dart';
import 'package:flutterapp/screens/home.dart';
import 'package:flutterapp/screens/second.dart';
import 'package:flutterapp/screens/third.dart';

import 'routes.dart';

// Función genérica para obtener los argumentos pasados a una ruta específica
T getArguments<T>(BuildContext context) {
  // Obtiene la ruta actual del contexto y recupera los argumentos asociados a ella.
  // Se asegura de que los argumentos se conviertan al tipo genérico especificado (T).
  return ModalRoute.of(context)!.settings.arguments as T;
}

// Mapa que define las rutas de la aplicación y sus correspondientes widgets (pantallas)
Map<String, Widget Function(BuildContext)> get appRoutes {
  // Retorna un mapa donde las claves son las rutas (nombres de las rutas) y los valores
  // son funciones que construyen las páginas correspondientes.
  return {
    // Ruta para la pantalla de bienvenida (SplashScreen)
    Routes.splash: (_) => SplashScreen(),

    // Ruta para la página de inicio de sesión
    Routes.login: (_) => LoginPage(),

    // Ruta para la página de cierre de sesión
    Routes.logout: (_) => LogoutPage(),

    // Ruta para la página de registro de usuario
    Routes.registration: (_) => RegistrationPage(),

    // Ruta para la página de perfil de usuario
    Routes.profile: (_) => ProfilePage(),

    // Ruta para la página de configuración
    Routes.settings: (_) => SettingsPage(),

    // Ruta para la página principal de la aplicación
    Routes.home: (_) => const Home(),

    // Ruta para la página de eventos
    Routes.events: (_) => const Second(),

    // Ruta para la página de reservas
    Routes.reserve: (_) => const Third(),

    // Ruta para la página de locales
    Routes.locals: (_) => LocalesPage(),
  };
}