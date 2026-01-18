import 'package:shared_preferences/shared_preferences.dart';
import '../models/decision_entry.dart';

/// Local storage for decision history
/// Max 50 entries, auto-deletes oldest when exceeded
class LocalStore {
  static const String _historyKey = 'parallel_history';
  static const int _maxEntries = 50;

  SharedPreferences? _prefs;

  /// Initialize shared preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all saved entries (newest first)
  Future<List<DecisionEntry>> getHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final String? jsonString = _prefs!.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final entries = DecisionEntry.decodeList(jsonString);
      // Return newest first
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Save a new entry
  /// Automatically removes oldest if limit exceeded
  Future<void> saveEntry(DecisionEntry entry) async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final entries = await getHistory();
    
    // Add new entry at the beginning
    entries.insert(0, entry);
    
    // Remove oldest entries if we exceed max
    while (entries.length > _maxEntries) {
      entries.removeLast();
    }
    
    // Save to storage
    final jsonString = DecisionEntry.encodeList(entries);
    await _prefs!.setString(_historyKey, jsonString);
  }

  /// Delete an entry by ID
  Future<void> deleteEntry(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final entries = await getHistory();
    entries.removeWhere((e) => e.id == id);
    
    final jsonString = DecisionEntry.encodeList(entries);
    await _prefs!.setString(_historyKey, jsonString);
  }

  /// Get a specific entry by ID
  Future<DecisionEntry?> getEntry(String id) async {
    final entries = await getHistory();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_historyKey);
  }

  /// Get SharedPreferences instance (for MemoryService)
  Future<SharedPreferences> getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
