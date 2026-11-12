import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const String kNotificationSettingsKey = 'setting_notifications';
  static const String kHasRequestedPermissionKey = 'notification_permission_requested';

  Function(String payload)? onNotificationTapped;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          if (onNotificationTapped != null) {
            onNotificationTapped!(response.payload!);
          }
        }
      },
    );

    await refreshNotificationSchedules();
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kNotificationSettingsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationSettingsKey, enabled);

    if (enabled) {
      await requestPermissions();
      await refreshNotificationSchedules();
    } else {
      await cancelAllNotifications();
    }
  }

  Future<bool> requestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHasRequestedPermissionKey, true);

    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Permission request error: ');
    }

    return true;
  }

  Future<void> refreshNotificationSchedules() async {
    final bool enabled = await isNotificationsEnabled();
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    await _scheduleDailyChallengeReminder();
    await _scheduleInactivityReminder();
  }

  Future<void> _scheduleDailyChallengeReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_challenge_channel',
        'Daily Challenge Reminders',
        channelDescription: 'Reminds you to play today\'s Daily Challenge',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: 1001,
        title: 'Daily Challenge Ready! 🌟',
        body: 'Play today\'s challenge to earn +100 Coins & maintain your streak!',
        notificationDetails: details,
        payload: 'daily_challenge',
      );
    } catch (e) {
      debugPrint('Error scheduling daily challenge notification: ');
    }
  }

  Future<void> _scheduleInactivityReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'inactivity_reminder_channel',
        'Inactivity Reminders',
        channelDescription: 'Reminds you when you haven\'t played in a while',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin.show(
        id: 1002,
        title: 'We miss you in Word Adventure! 🔍',
        body: 'New word puzzles are waiting for you. Come sharpen your brain!',
        notificationDetails: details,
        payload: 'home',
      );
    } catch (e) {
      debugPrint('Error scheduling inactivity notification: ');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling notifications: ');
    }
  }
}
