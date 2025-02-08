
import 'package:workmanager/workmanager.dart';
import 'local_notifications_service.dart';
import 'dart:async';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Ejecutando tarea en segundo plano...");

    // Obtener la hora actual
    DateTime now = DateTime.now();
    int hour = now.hour;

    // Enviar notificación solo en horario de promociones (10 AM - 6 PM)
    if (hour >= 10 && hour <= 18) {
      LocalNotificationService().mostrarNotificacion(
        "🎉 ¡Oferta Especial en CanchAPP! ⚽",
        "Reserva tu cancha hoy y obtén un 2x1 en la tarifa. ¡No te lo pierdas!"
      );
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      "backgroundTask",
      "fetchData",
      frequency: const Duration(minutes: 30), // Ejecuta cada 30 minutos
    );
  }
}
