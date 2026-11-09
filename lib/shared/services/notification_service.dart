import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('requestPermissions error: $e');
    }
    return false;
  }

  Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      // Periodic daily notification (using repeat interval or daily at time)
      await _notificationsPlugin.periodicallyShow(
        AppConstants.bedtimeNotificationId,
        'Bedtime Approaching',
        'Your scheduled bedtime is nearing. Wind down and prepare for restful sleep.',
        RepeatInterval.daily,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule bedtime reminder: $e');
    }
  }

  Future<void> scheduleWakeReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.periodicallyShow(
        AppConstants.wakeNotificationId,
        'Good Morning',
        'Wake-up time. Remember to log or finalize your sleep session in SleepTrack.',
        RepeatInterval.daily,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule wake reminder: $e');
    }
  }

  Future<void> cancelBedtimeReminder() async {
    try {
      await _notificationsPlugin.cancel(AppConstants.bedtimeNotificationId);
    } catch (e) {
      debugPrint('Error canceling bedtime reminder: $e');
    }
  }

  Future<void> cancelWakeReminder() async {
    try {
      await _notificationsPlugin.cancel(AppConstants.wakeNotificationId);
    } catch (e) {
      debugPrint('Error canceling wake reminder: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}

