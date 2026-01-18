import 'dart:convert';

/// Model representing a decision entry with its parallel futures
class DecisionEntry {
  final String id;
  final String decision;
  final String tone; // 'reflective' or 'light'
  final DateTime date;
  final String resultIfAct;
  final String resultIfNot;
  final List<String> tags; // extracted keywords for continuity matching

  DecisionEntry({
    required this.id,
    required this.decision,
    required this.tone,
    required this.date,
    required this.resultIfAct,
    required this.resultIfNot,
    this.tags = const [],
  });

  /// Create an entry with auto-generated ID
  factory DecisionEntry.create({
    required String decision,
    required String tone,
    required String resultIfAct,
    required String resultIfNot,
    List<String> tags = const [],
  }) {
    return DecisionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      decision: decision,
      tone: tone,
      date: DateTime.now(),
      resultIfAct: resultIfAct,
      resultIfNot: resultIfNot,
      tags: tags,
    );
  }

  /// Shortened decision for list display
  String get shortDecision {
    if (decision.length <= 40) return decision;
    return '${decision.substring(0, 40)}...';
  }

  /// Formatted date for display
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Capitalize tone for display
  String get displayTone {
    return tone[0].toUpperCase() + tone.substring(1);
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'decision': decision,
      'tone': tone,
      'date': date.toIso8601String(),
      'resultIfAct': resultIfAct,
      'resultIfNot': resultIfNot,
      'tags': tags,
    };
  }

  /// Create from JSON map (backward compatible - handles missing tags)
  factory DecisionEntry.fromJson(Map<String, dynamic> json) {
    return DecisionEntry(
      id: json['id'] as String,
      decision: json['decision'] as String,
      tone: json['tone'] as String,
      date: DateTime.parse(json['date'] as String),
      resultIfAct: json['resultIfAct'] as String,
      resultIfNot: json['resultIfNot'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Encode list to JSON string
  static String encodeList(List<DecisionEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// Decode JSON string to list
  static List<DecisionEntry> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => DecisionEntry.fromJson(json)).toList();
  }
}
