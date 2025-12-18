import 'package:shared_preferences/shared_preferences.dart';

/// A tiny persistence layer for recent search queries.
///
/// - Stores a list of strings in SharedPreferences
/// - Deduplicates and keeps most-recent-first
/// - Caps to [maxItems]
class RecentSearchesStore {
  RecentSearchesStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _key = 'recent_search_queries';
  static const int maxItems = 8;

  final SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async => _prefs ?? SharedPreferences.getInstance();

  Future<List<String>> load() async {
    final prefs = await _instance;
    final items = prefs.getStringList(_key) ?? const <String>[];
    // Normalize: trim + drop empties
    return items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await _instance;
    final current = (prefs.getStringList(_key) ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    current.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    current.insert(0, q);

    if (current.length > maxItems) {
      current.removeRange(maxItems, current.length);
    }

    await prefs.setStringList(_key, current);
  }

  Future<void> remove(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await _instance;
    final current = (prefs.getStringList(_key) ?? const <String>[])..removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    await prefs.setStringList(_key, current);
  }

  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_key);
  }
}

