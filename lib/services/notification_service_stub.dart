class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}

  Future<bool> areNotificationsEnabled() async => true;

  Future<void> setNotificationsEnabled(bool enabled) async {}

  Future<void> requestPermissions() async {}

  Future<void> cancelAll() async {}

  Future<void> scheduleMilestones({
    required double energie,
    required double birse,
    required double trads,
    required String activity,
    required String name,
  }) async {}
}
