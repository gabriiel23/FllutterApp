import 'package:flutter/material.dart';
import 'package:flutterapp/core/routes/navegation/navigationBar.dart';
import 'package:flutterapp/features/canchas/presentation/pages/newCancha_page.dart';

import 'package:flutterapp/features/comunity/presentation/pages/groups_page.dart';
import 'package:flutterapp/features/home/presentation/pages/home_page.dart';
import 'package:flutterapp/features/canchas/presentation/pages/canchas_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profilePlayer_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/reserves_page.dart';
import 'package:flutterapp/features/profile/presentation/pages/profile_page.dart';

import 'package:flutterapp/features/registerUser/presentation/pages/login_page.dart';
import 'package:flutterapp/features/registerUser/presentation/pages/logout_page.dart';
// import 'package:flutterapp/core/routes/navegation/navigationBar.dart';
import 'package:flutterapp/features/comunity/presentation/pages/newGroup_page.dart';
import 'package:flutterapp/features/reserves/presentation/pages/newReserve_page.dart';
import 'package:flutterapp/features/payment/presentation/pages/payment_page.dart';
import 'package:flutterapp/features/registerUser/presentation/pages/registration_page.dart';
import 'package:flutterapp/features/settings/presentation/pages/settings_page.dart';
import 'package:flutterapp/features/home/presentation/pages/splash_page.dart';
import 'routes.dart';

Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    // Rutas principales con BottomNavigationBar
    Routes.login: (_) => const LoginPage(),
    Routes.home: (_) => const MainScreen(),

    // Rutas secundarias sin BottomNavigationBar
    Routes.splash: (_) => SplashScreen(),
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
    Routes.newCanchaPage: (_) => NewCanchaPage(),
    Routes.profilePlayer: (_) => ProfilePlayerPage(),




    Routes.events: (_) => const Home(),
  };
}
