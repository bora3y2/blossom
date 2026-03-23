import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          appRouter.push('/garden_plant/$payload');
        }
      },
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // Android permissions are requested dynamically in Android 13+
  }

  Future<void> scheduleWateringReminder({
    required String plantId,
    required String plantName,
    required DateTime nextWaterDate,
  }) async {
    // Ensure schedule date is in the future.
    if (nextWaterDate.isBefore(DateTime.now())) {
      return;
    }

    // Convert plantId to a stable int so we don't spam overlapping notifications for one plant
    final int notificationId = plantId.hashCode;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Time to water $plantName!',
      body: 'Your $plantName is thirsty. Give it some water soon.',
      payload: plantId,
      scheduledDate: tz.TZDateTime.from(nextWaterDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel_id',
          'Watering Reminders',
          channelDescription: 'Reminders to water your plants',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String plantId) async {
    await _flutterLocalNotificationsPlugin.cancel(id: plantId.hashCode);
  }
}

final notificationService = NotificationService();
