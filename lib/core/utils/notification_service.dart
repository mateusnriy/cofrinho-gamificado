import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Em ambientes de teste ou na web, evita chamadas a plugins nativos móveis
  static bool disabledForTesting = false;
  static bool get _isTesting =>
      kIsWeb ||
      disabledForTesting ||
      (WidgetsBinding.instance.runtimeType.toString().contains('Test'));

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isTesting) return;
    // Inicialização do TimeZone para agendamentos exatos
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicita permissão (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {}

  /// Agenda um lembrete diário para uma meta específica usando agendamento real
  Future<void> scheduleGoalReminder({
    required int notificationId,
    required String goalName,
    required String timeStr, // "08:00"
  }) async {
    if (_isTesting) return;
    const androidDetails = AndroidNotificationDetails(
      'goal_reminders',
      'Lembretes de metas',
      channelDescription: 'Notificações para lembrar de registrar economias',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      '🐷 Cofrinho Digital',
      'Não se esqueça de registrar a sua economia de hoje para "$goalName"!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelGoalReminder(int notificationId) async {
    if (_isTesting) return;
    try {
      await _plugin
          .cancel(notificationId)
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (_isTesting) return;
    try {
      await _plugin.cancelAll().timeout(const Duration(milliseconds: 300));
    } catch (_) {}
  }

  Future<void> showCompletionNotification({
    required String goalName,
  }) async {
    if (_isTesting) return;
    const androidDetails = AndroidNotificationDetails(
      'goal_completion',
      'Metas concluídas',
      channelDescription: 'Celebração ao atingir uma meta',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        99999,
        '🎉 Meta atingida!',
        'Parabéns! Concluiu a meta "$goalName"!',
        details,
      ).timeout(const Duration(milliseconds: 300));
    } catch (_) {}
  }
}
