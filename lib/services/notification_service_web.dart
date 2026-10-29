import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../constants/notification_messages.dart';
import '../constants/stat_weights.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefKeyNotificationsEnabled = 'notifications_enabled';
  final List<Timer> _activeTimers = [];

  Future<void> init() async {}

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

  bool get _hasNotification {
    try {
      web.Notification.permission;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermissions() async {
    if (_hasNotification) {
      final permission = web.Notification.permission;
      if (permission != 'granted' && permission != 'denied') {
        await web.Notification.requestPermission().toDart;
      }
    }
  }

  Future<void> cancelAll() async {
    for (var timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
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
    if (!await areNotificationsEnabled()) {
      await cancelAll();
      return;
    }

    await cancelAll();
    if (activity == 'idle') return;

    if (_hasNotification && web.Notification.permission != 'granted') {
      await web.Notification.requestPermission().toDart;
    }

    final rates = _getRates(activity);
    final rateEnergie = rates['energie'] ?? 0.0;
    final rateBirse = rates['birse'] ?? 0.0;
    final rateTrads = rates['trads'] ?? 0.0;

    void scheduleWebItem(int seconds, NotificationContent item) {
      if (seconds <= 0) return;
      final timer = Timer(Duration(seconds: seconds), () {
        if (_hasNotification && web.Notification.permission == 'granted') {
          web.Notification(item.title, web.NotificationOptions(body: item.body(name)));
        }
      });
      _activeTimers.add(timer);
    }

    // 1. Energie à 0
    if (rateEnergie < 0 && energie > 0) {
      final seconds = (energie / (-rateEnergie)).ceil();
      scheduleWebItem(seconds, NotificationMessages.energieEpuisee);
    }

    // 2. Birse à 50
    if (rateBirse > 0 && birse < 50.0) {
      final seconds = ((50.0 - birse) / rateBirse).ceil();
      scheduleWebItem(seconds, NotificationMessages.birse100Jours);
    }

    // 3. Birse à 100
    if (rateBirse > 0 && birse < 100.0) {
      final seconds = ((100.0 - birse) / rateBirse).ceil();
      scheduleWebItem(seconds, NotificationMessages.birseDelivrance);
    }

    // 4. Trad's à 50
    if (rateTrads > 0 && trads < 50.0) {
      final seconds = ((50.0 - trads) / rateTrads).ceil();
      scheduleWebItem(seconds, NotificationMessages.tradsBapts);
    }

    // 5. Trad's à 100
    if (rateTrads > 0 && trads < 100.0) {
      final seconds = ((100.0 - trads) / rateTrads).ceil();
      scheduleWebItem(seconds, NotificationMessages.tradsMaster);
    }

    // 6. Trad's à 0
    if (rateTrads < 0 && trads > 0) {
      final seconds = (trads / (-rateTrads)).ceil();
      scheduleWebItem(seconds, NotificationMessages.tradsAlerteHU);
    }
  }
}
