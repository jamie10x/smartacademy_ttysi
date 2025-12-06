import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

final searchRepositoryProvider = Provider((ref) {
  return SearchRepository(Supabase.instance.client);
});

// Provider for the search results based on a query string
final searchUsersProvider = FutureProvider.family<List<UserProfile>, String>((ref, query) async {
  return ref.read(searchRepositoryProvider).searchUsers(query);
});

class SearchRepository {
  final SupabaseClient _supabase;
  SearchRepository(this._supabase);

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final data = await _supabase
        .from('profiles')
        .select()
        .or('name.ilike.%$query%,surname.ilike.%$query%'); // Search Name OR Surname

    return (data as List).map((e) => UserProfile.fromMap(e)).toList();
  }

  Future<void> followUser(String targetUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    await _supabase.from('followers').insert({
      'user_id': targetUserId,
      'follower_id': myId,
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    await _supabase.from('followers').delete().match({
      'user_id': targetUserId,
      'follower_id': myId,
    });
  }

  // Check if I am following a specific user
  Future<bool> isFollowing(String targetUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('followers')
        .select()
        .match({'user_id': targetUserId, 'follower_id': myId})
        .maybeSingle(); // Returns null if not found

    return data != null;
  }
}