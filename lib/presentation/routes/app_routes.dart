import 'package:flutter/material.dart';
import 'package:flutterapp/presentation/groups_page.dart';
import 'package:flutterapp/presentation/home_page.dart';
import 'package:flutterapp/presentation/canchas_page.dart';
import 'package:flutterapp/presentation/locales_page.dart';
import 'package:flutterapp/presentation/login_page.dart';
import 'package:flutterapp/presentation/logout_page.dart';
import 'package:flutterapp/presentation/navegation/navigationBar.dart';
import 'package:flutterapp/presentation/newGroup_page.dart';
import 'package:flutterapp/presentation/profile_page.dart';
import 'package:flutterapp/presentation/registration_page.dart';
import 'package:flutterapp/presentation/reserves_page.dart';
import 'package:flutterapp/presentation/settings_page.dart';
import 'package:flutterapp/presentation/splash_page.dart';
import 'routes.dart';

Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    // Rutas principales con BottomNavigationBar
    Routes.home: (_) => const MainScreen(),

    // Rutas secundarias sin BottomNavigationBar
    Routes.splash: (_) => SplashScreen(),
    Routes.login: (_) => LoginPage(),
    Routes.logout: (_) => LogoutPage(),
    Routes.registration: (_) => RegistrationPage(),
    Routes.profile: (_) => ProfilePage(),
    Routes.settings: (_) => SettingsPage(),
    Routes.locals: (_) => LocalesPage(),
    Routes.newGroupPage: (_) => NewGroupPage(),
    Routes.groups: (_) => Groups(),
    Routes.reserves: (_) => Reserves(),
    Routes.canchas: (_) => Canchas(),




    Routes.events: (_) => const Home(),
  };
}
