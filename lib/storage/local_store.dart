import 'package:shared_preferences/shared_preferences.dart';
import '../models/dream.dart';

class LocalStore {
  static const String _historyKey = 'ufuq_dreams';
  static const String _holmiHistoryKey = 'holmi_dreams';
  static const String _legacyHistoryKey = 'parallel_history';
  static const int maxEntries = 50;
  SharedPreferences? _prefs;
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Dream>> getDreams() async {
    _prefs ??= await SharedPreferences.getInstance();
    var raw = _prefs!.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      final holmiData = _prefs!.getString(_holmiHistoryKey);
      if (holmiData != null && holmiData.isNotEmpty) {
        await _prefs!.setString(_historyKey, holmiData);
        raw = holmiData;
      }
    }
    if (raw == null || raw.isEmpty) {
      final legacy = _prefs!.getString(_legacyHistoryKey);
      if (legacy != null && legacy.isNotEmpty) {
        try {
          final entries = Dream.decodeList(legacy);
          final migrated = entries
              .map(
                (old) => Dream(
                  id: old.id,
                  title: old.text
                      .trim()
                      .split(RegExp(r'\s+'))
                      .take(7)
                      .join(' '),
                  text: old.text,
                  actions: const [],
                  scenarioDo: old.scenarioDo,
                  scenarioNot: old.scenarioNot,
                  createdAt: old.createdAt,
                  tags: old.tags,
                ),
              )
              .take(maxEntries)
              .toList();
          await _prefs!.setString(_historyKey, Dream.encodeList(migrated));
          await _prefs!.remove(_legacyHistoryKey);
          raw = Dream.encodeList(migrated);
        } catch (_) {
          await _prefs!.remove(_legacyHistoryKey);
        }
      }
    }
    if (raw == null || raw.isEmpty) return [];
    try {
      final dreams = Dream.decodeList(raw);
      dreams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return dreams;
    } catch (_) {
      return [];
    }
  }

  Future<List<Dream>> getHistory() => getDreams();
  Future<void> saveDream(Dream dream) async {
    _prefs ??= await SharedPreferences.getInstance();
    final dreams = await getDreams();
    dreams.removeWhere((d) => d.id == dream.id);
    dreams.insert(0, dream);
    if (dreams.length > maxEntries) {
      dreams.removeRange(maxEntries, dreams.length);
    }
    await _prefs!.setString(_historyKey, Dream.encodeList(dreams));
  }

  Future<void> saveEntry(Dream dream) => saveDream(dream);
  Future<void> deleteDream(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final dreams = await getDreams()
      ..removeWhere((d) => d.id == id);
    await _prefs!.setString(_historyKey, Dream.encodeList(dreams));
  }

  Future<void> deleteEntry(String id) => deleteDream(id);
  Future<Dream?> getDream(String id) async {
    for (final d in await getDreams()) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<Dream?> getEntry(String id) => getDream(id);
  Future<void> clearHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_historyKey);
  }

  Future<SharedPreferences> getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
