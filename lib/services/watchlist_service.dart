
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistService extends ChangeNotifier {
  WatchlistService._();

  static final WatchlistService instance = WatchlistService._();

  static const String _storageKey = 'watchlist';

  int _count = 0;

  int get count => _count;

  Future<List<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? [];

    // Remove duplicate IDs while preserving their order.
    final uniqueIds = ids.toSet().toList();

    if (uniqueIds.length != ids.length) {
      await prefs.setStringList(_storageKey, uniqueIds);
    }

    _count = uniqueIds.length;
    notifyListeners();

    return uniqueIds;
  }

  Future<void> loadCount() async {
    await getSavedIds();
  }

  Future<bool> addMovie(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? [];
    final id = movieId.toString();

    if (ids.contains(id)) {
      _count = ids.toSet().length;
      notifyListeners();
      return false;
    }

    ids.add(id);

    final saved = await prefs.setStringList(_storageKey, ids);

    if (saved) {
      _count = ids.length;
      notifyListeners();
    }

    return saved;
  }

  Future<void> removeMovie(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? [];

    ids.remove(movieId.toString());

    await prefs.setStringList(_storageKey, ids);

    _count = ids.toSet().length;
    notifyListeners();
  }
}
