import 'dart:convert';

class DreamAction {
  final String text;
  final bool done;
  const DreamAction({required this.text, this.done = false});
  DreamAction copyWith({String? text, bool? done}) =>
      DreamAction(text: text ?? this.text, done: done ?? this.done);
  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  factory DreamAction.fromJson(Map<String, dynamic> json) => DreamAction(
    text: json['text'] as String,
    done: json['done'] as bool? ?? false,
  );
}

class DreamReminder {
  final bool enabled;
  final String days;
  final String time;
  final int? weeklyDay;
  const DreamReminder({
    this.enabled = false,
    this.days = 'daily',
    this.time = '09:00',
    this.weeklyDay,
  });
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'days': days,
    'time': time,
    'weeklyDay': weeklyDay,
  };
  factory DreamReminder.fromJson(Map<String, dynamic>? json) => DreamReminder(
    enabled: json?['enabled'] as bool? ?? false,
    days: json?['days'] as String? ?? 'daily',
    time: json?['time'] as String? ?? '09:00',
    weeklyDay: json?['weeklyDay'] as int?,
  );
}

class Dream {
  final String id;
  final String title;
  final String text;
  final List<DreamAction> actions;
  final String scenarioDo;
  final String scenarioNot;
  final DateTime createdAt;
  final DreamReminder reminder;
  final List<String> tags;
  const Dream({
    required this.id,
    required this.title,
    required this.text,
    required this.actions,
    required this.scenarioDo,
    required this.scenarioNot,
    required this.createdAt,
    this.reminder = const DreamReminder(),
    this.tags = const [],
  });
  Dream copyWith({
    String? title,
    String? text,
    List<DreamAction>? actions,
    String? scenarioDo,
    String? scenarioNot,
    DreamReminder? reminder,
    List<String>? tags,
  }) => Dream(
    id: id,
    title: title ?? this.title,
    text: text ?? this.text,
    actions: actions ?? this.actions,
    scenarioDo: scenarioDo ?? this.scenarioDo,
    scenarioNot: scenarioNot ?? this.scenarioNot,
    createdAt: createdAt,
    reminder: reminder ?? this.reminder,
    tags: tags ?? this.tags,
  );
  String get nextStep {
    for (final action in actions) {
      if (!action.done) return action.text;
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    'actions': actions.map((a) => a.toJson()).toList(),
    'scenarioDo': scenarioDo,
    'scenarioNot': scenarioNot,
    'createdAt': createdAt.toIso8601String(),
    'reminder': reminder.toJson(),
    'tags': tags,
  };
  factory Dream.fromJson(Map<String, dynamic> json) => Dream(
    id: json['id'] as String,
    title:
        json['title'] as String? ??
        (json['text'] as String? ?? json['decision'] as String? ?? ''),
    text: json['text'] as String? ?? json['decision'] as String? ?? '',
    actions: (json['actions'] as List<dynamic>? ?? [])
        .map((a) => DreamAction.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
    scenarioDo:
        json['scenarioDo'] as String? ?? json['resultIfAct'] as String? ?? '',
    scenarioNot:
        json['scenarioNot'] as String? ?? json['resultIfNot'] as String? ?? '',
    createdAt:
        DateTime.tryParse(
          json['createdAt'] as String? ?? json['date'] as String? ?? '',
        ) ??
        DateTime.now(),
    reminder: DreamReminder.fromJson(json['reminder'] as Map<String, dynamic>?),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );
  static String encodeList(List<Dream> dreams) =>
      jsonEncode(dreams.map((d) => d.toJson()).toList());
  static List<Dream> decodeList(String data) =>
      (jsonDecode(data) as List<dynamic>)
          .map((d) => Dream.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();
}
