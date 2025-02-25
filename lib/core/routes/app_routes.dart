import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutterapp/features/canchas/presentation/pages/newCancha_page.dart';
import 'package:flutterapp/features/comunity/presentation/pages/groups_page.dart';
import 'package:flutterapp/features/home/presentation/pages/home_page.dart';
import 'package:flutterapp/features/canchas/presentation/pages/canchas_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profilePlayer_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profile_page.dart';

import 'package:flutterapp/features/registerUser/presentation/pages/login_page.dart';
import 'package:flutterapp/features/registerUser/presentation/pages/logout_page.dart';
import 'package:flutterapp/core/routes/navegation/navigationBar.dart';
import 'package:flutterapp/features/comunity/presentation/pages/newGroup_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/newReserve_page.dart';
import 'package:flutterapp/features/payment/presentation/pages/payment_page.dart';
import 'package:flutterapp/features/registerUser/presentation/pages/registration_page.dart';
import 'package:flutterapp/features/settings/presentation/pages/settings_page.dart';
import 'package:flutterapp/features/home/presentation/pages/splash_page.dart';

import 'routes.dart';

/// Método para verificar el rol del usuario
Future<bool> hasRole(String requiredRole) async {
  final prefs = await SharedPreferences.getInstance();
  String? userRole = prefs.getString('userRol'); // Obtener rol almacenado
  return userRole == requiredRole; // Comparar con el requerido
}

/// Función para proteger rutas según el rol del usuario
Widget roleGuard(Widget page, String requiredRole) {
  return FutureBuilder<bool>(
    future: hasRole(requiredRole),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasData && snapshot.data == true) {
        return page; // Access granted
      }
      return const Home(); // Redirect to Home (or another page)
    },
  );
}

/// Rutas de la aplicación con restricciones de acceso
Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    // Rutas principales con BottomNavigationBar
    Routes.home: (_) => const MainScreen(),

    // Rutas sin restricciones
    Routes.splash: (_) => SplashScreen(),
    Routes.login: (_) => LoginPage(),
    Routes.logout: (_) => LogoutPage(),
    Routes.registration: (_) => RegistrationPage(),
    Routes.profile: (_) => ProfilePage(),
    Routes.settings: (_) => SettingsPage(),
    Routes.newGroupPage: (_) => NewGroupPage(),
    Routes.groups: (_) => Groups(),
    Routes.reserves: (_) => Reserves(),
    Routes.canchas: (_) => Canchas(),
    Routes.newReservePage: (_) => NewReservePage(),
    Routes.payment: (_) => PaymentPage(),
    Routes.profilePlayer: (_) => ProfilePlayerPage(),

    // Rutas con restricción de acceso
    Routes.newCanchaPage: (_) => roleGuard(NewCanchaPage(), "dueño"), // Solo accesible para "dueño"

    // Otra ruta
    Routes.events: (_) => const Home(),
  };
}
