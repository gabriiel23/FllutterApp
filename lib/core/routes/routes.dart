
class Routes {
  // Constructor privado
  Routes._();

  // Ruta inicial
  static const initialRoute = splash;

  // Rutas principales (con BottomNavigationBar)
  static const home = '/home';
  // static const cancha = '/cancha';
  static const espacio = '/espacio';
  static const profile = '/profile';
  static const reserves = '/reserves';
  static const reserves_user = '/reserves_user';

  // Rutas secundarias (sin BottomNavigationBar)
  static const splash = '/splash';
  static const login = '/login';
  static const logout = '/logout';
  static const registration = '/registration';
  static const settings = '/settings';
  static const events = '/events';
  static const groups = '/groups';
  static const newGroupPage = '/newGroup';
  // static const canchas = '/cachas';
  static const espacios = '/espacios';
  static const espaciosAdmin = '/espacios_admin';
  static const newReservePage = '/newReserve';
  static const payment = '/payment';
  static const newCanchaPage = '/newCancha';
  static const newEspacioPage = '/newEspacio';
  static const profilePlayer = '/profilePlayer';
  static const homeAdmin = '/homeAdmin';
}

