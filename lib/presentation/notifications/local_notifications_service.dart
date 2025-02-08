
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  void mostrarNotificacion(String titulo, String mensaje) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cancha_notificaciones', 'Notificaciones de CanchAPP',
      importance: Importance.high, priority: Priority.high);
    
    const NotificationDetails generalDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, titulo, mensaje, generalDetails);
  }
}

