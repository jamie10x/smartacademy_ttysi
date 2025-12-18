import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recent_searches_store.dart';

final recentSearchesStoreProvider = Provider<RecentSearchesStore>((ref) {
  return RecentSearchesStore();
});

/// Recent searches list.
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(recentSearchesStoreProvider).load();
});

/// Add a recent query and refresh the list.
final addRecentSearchProvider = FutureProvider.family<void, String>((ref, query) async {
  await ref.read(recentSearchesStoreProvider).add(query);
  ref.invalidate(recentSearchesProvider);
});

/// Remove a single recent query and refresh the list.
final removeRecentSearchProvider = FutureProvider.family<void, String>((ref, query) async {
  await ref.read(recentSearchesStoreProvider).remove(query);
  ref.invalidate(recentSearchesProvider);
});

/// Clear all recent searches and refresh the list.
final clearRecentSearchesProvider = FutureProvider<void>((ref) async {
  await ref.read(recentSearchesStoreProvider).clear();
  ref.invalidate(recentSearchesProvider);
});

