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

T getArguments<T>(BuildContext context) {
  return ModalRoute.of(context)!.settings.arguments as T;
}

Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    Routes.splash: (_) => SplashScreen(),
    Routes.login: (_) => LoginPage(),
    Routes.logout: (_) => LogoutPage(),
    Routes.registration: (_)=> RegistrationPage(),
    Routes.profile: (_)=> ProfilePage(),
    Routes.settings: (_)=> SettingsPage(),
    Routes.home: (_) => const Home(),
    Routes.events: (_) => const Second(),
    Routes.reserve: (_) => const Third(),
    Routes.locals:(_) => const LocalesPage(),
  };
}