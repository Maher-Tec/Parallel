import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/dream.dart';
import '../storage/local_store.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _ready = true;
    await rescheduleAll();
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidAllowed = android == null
        ? true
        : await android.requestNotificationsPermission() ?? true;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosAllowed = ios == null
        ? true
        : await ios.requestPermissions(alert: true, badge: true, sound: true) ??
              true;
    return androidAllowed && iosAllowed;
  }

  int _id(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> schedule(Dream dream) async {
    await initialize();
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(_id(dream.id) + day);
    }
    if (!dream.reminder.enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    final parts = dream.reminder.time.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final weekdays = dream.reminder.days == 'weekdays'
        ? [1, 2, 3, 4, 5]
        : dream.reminder.days == 'weekly'
        ? [dream.reminder.weeklyDay ?? dream.createdAt.weekday]
        : List<int>.generate(7, (i) => i + 1);
    final action = dream.nextStep;
    final arabic = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
    ).hasMatch(dream.text);
    final french = RegExp(
      r"\b(le|la|les|mon|ma|mes|je|mon rêve|mon objectif)\b",
      caseSensitive: false,
    ).hasMatch(dream.text);
    final title = arabic
        ? 'لا تنس حلمك: ${dream.title}'
        : french
        ? 'N’oubliez pas votre rêve : ${dream.title}'
        : "Don't forget your dream: ${dream.title}";
    final body = action.isEmpty
        ? (arabic
              ? 'أنجزت كل الخطوات. أضف خطوات جديدة لحلمك.'
              : french
              ? 'Toutes les étapes sont faites. Ajoutez-en de nouvelles.'
              : 'You have completed these steps. Add new steps for your dream.')
        : (arabic
              ? 'خطوتك التالية: $action'
              : french
              ? 'Prochaine étape : $action'
              : 'Next step: $action');
    for (final weekday in weekdays) {
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _id(dream.id) + weekday,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dream_reminders',
            'Dream reminders',
            channelDescription: 'Gentle reminders for your next dream step',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancel(String id) async {
    await initialize();
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(_id(id) + day);
    }
  }

  Future<void> refresh(Dream dream) async {
    await initialize();
    await cancel(dream.id);
    await schedule(dream);
  }

  Future<void> rescheduleAll() async {
    if (!_ready) return;
    final store = LocalStore();
    for (final dream in await store.getDreams()) {
      await schedule(dream);
    }
  }
}
