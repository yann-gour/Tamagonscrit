import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/notification_messages.dart';
import '../constants/stat_weights.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _prefKeyNotificationsEnabled = 'notifications_enabled';

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, enabled);
    if (!enabled) {
      await cancelAll();
    }
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Map<String, double> _getRates(String activity) {
    double rateEnergie = 0.0;
    double rateBirse = 0.0;
    double rateTrads = 0.0;

    switch (activity) {
      case 'birse':
        rateEnergie = -1.0 * StatWeights.weightEnergie;
        rateBirse = 0.5 * StatWeights.weightBirse;
        rateTrads = -0.2 * StatWeights.weightTrads;
        break;
      case 'ronque':
        rateEnergie = 1.0 * StatWeights.weightEnergie;
        break;
      case 'monome':
        rateEnergie = -1.0 * StatWeights.weightEnergie;
        rateTrads = 0.5 * StatWeights.weightTrads;
        break;
      case 'chouille':
        rateEnergie = -2.0 * StatWeights.weightEnergie;
        rateBirse = -0.2 * StatWeights.weightBirse;
        rateTrads = 0.4 * StatWeights.weightTrads;
        break;
      case 'fins':
        rateEnergie = 1.0 * StatWeights.weightEnergie;
        rateTrads = 0.4 * StatWeights.weightTrads;
        break;
      case 'idle':
      default:
        break;
    }
    return {
      'energie': rateEnergie,
      'birse': rateBirse,
      'trads': rateTrads,
    };
  }

  Future<void> scheduleMilestones({
    required double energie,
    required double birse,
    required double trads,
    required String activity,
    required String name,
  }) async {
    await init();

    if (!await areNotificationsEnabled()) {
      await cancelAll();
      return;
    }

    await cancelAll();

    if (activity == 'idle') return;

    final rates = _getRates(activity);
    final rateEnergie = rates['energie'] ?? 0.0;
    final rateBirse = rates['birse'] ?? 0.0;
    final rateTrads = rates['trads'] ?? 0.0;

    final now = tz.TZDateTime.now(tz.local);

    // Helper pour programmer un NotificationContent
    Future<void> scheduleItem(
      NotificationContent item,
      tz.TZDateTime scheduledTime,
    ) async {
      await _scheduleNotification(
        id: item.id,
        title: item.title,
        body: item.body(name),
        scheduledTime: scheduledTime,
      );
    }

    // 1. Energie à 0
    if (rateEnergie < 0 && energie > 0) {
      final seconds = (energie / (-rateEnergie)).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.energieEpuisee,
          now.add(Duration(seconds: seconds)),
        );
      }
    }

    // 2. Birse à 50
    if (rateBirse > 0 && birse < 50.0) {
      final seconds = ((50.0 - birse) / rateBirse).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.birse100Jours,
          now.add(Duration(seconds: seconds)),
        );
      }
    }

    // 3. Birse à 100
    if (rateBirse > 0 && birse < 100.0) {
      final seconds = ((100.0 - birse) / rateBirse).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.birseDelivrance,
          now.add(Duration(seconds: seconds)),
        );
      }
    }

    // 4. Trad's à 50
    if (rateTrads > 0 && trads < 50.0) {
      final seconds = ((50.0 - trads) / rateTrads).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.tradsBapts,
          now.add(Duration(seconds: seconds)),
        );
      }
    }

    // 5. Trad's à 100
    if (rateTrads > 0 && trads < 100.0) {
      final seconds = ((100.0 - trads) / rateTrads).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.tradsMaster,
          now.add(Duration(seconds: seconds)),
        );
      }
    }

    // 6. Trad's à 0
    if (rateTrads < 0 && trads > 0) {
      final seconds = (trads / (-rateTrads)).ceil();
      if (seconds > 0) {
        await scheduleItem(
          NotificationMessages.tradsAlerteHU,
          now.add(Duration(seconds: seconds)),
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tamagonscrit_milestones',
        'Suivi du conscrit',
        channelDescription: 'Notifications pour les étapes importantes du conscrit',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Erreur lors de la programmation de la notification $id: $e');
    }
  }
}
