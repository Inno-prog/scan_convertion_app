import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final List<_AppNotification> _notifications = [];
  int _nextId = 1;

  List<_AppNotification> get notifications => List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showConversionSuccess(String fileName, String format) async {
    final title = 'Conversion réussie ✅';
    final body = '$fileName → $format converti avec succès';
    _addToInbox(title, body, NotifType.success);
    await _show(title, body);
  }

  Future<void> showConversionError(String fileName, String error) async {
    final title = 'Erreur de conversion ❌';
    final body = 'Impossible de convertir $fileName : $error';
    _addToInbox(title, body, NotifType.error);
    await _show(title, body);
  }

  Future<void> showConversionStarted(String fileName) async {
    final title = 'Conversion en cours ⏳';
    final body = 'Conversion de $fileName démarrée';
    _addToInbox(title, body, NotifType.info);
    await _show(title, body);
  }

  void _addToInbox(String title, String body, NotifType type) {
    _notifications.add(_AppNotification(
      id: _nextId++,
      title: title,
      body: body,
      type: type,
      date: DateTime.now(),
    ));
  }

  Future<void> _show(String title, String body) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'file_converter_channel',
      'FileConvert',
      channelDescription: 'Notifications de conversion de fichiers',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      _nextId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
  }

  void markRead(int id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) _notifications[idx].isRead = true;
  }

  void clearAll() => _notifications.clear();
}

enum NotifType { success, error, info }

class _AppNotification {
  final int id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime date;
  bool isRead;

  _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
  });
}
