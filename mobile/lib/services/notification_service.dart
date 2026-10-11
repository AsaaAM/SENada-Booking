import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle tap
        },
      );
    } catch (_) {}
  }

  Future<void> requestPermissions() async {
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> scheduleBookingReminder(int bookingId, String studioName, DateTime startTime) async {
    // Schedule 1 hour before start time
    final scheduledTime = startTime.subtract(const Duration(hours: 1));

    if (scheduledTime.isBefore(DateTime.now())) {
      // If it's already less than an hour away, we can't schedule it in the past.
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_reminder',
      'Booking Reminders',
      channelDescription: 'Reminders for upcoming studio bookings',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: bookingId,
      title: 'Pengingat Booking SENada',
      body: 'Sesi musikmu di $studioName akan mulai dalam 1 jam!',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
