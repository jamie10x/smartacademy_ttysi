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

/// Follow status provider for a single user.
///
/// Used by the search results list to avoid per-tile initState async calls.
final isFollowingProvider = FutureProvider.family<bool, String>((ref, targetUserId) async {
  return ref.read(searchRepositoryProvider).isFollowing(targetUserId);
});

/// Mutation provider to toggle follow/unfollow.
///
/// Note: callers should invalidate `isFollowingProvider(userId)` after running.
final toggleFollowProvider = FutureProvider.family<void, ({String targetUserId, bool isCurrentlyFollowing})>(
  (ref, args) async {
    final repo = ref.read(searchRepositoryProvider);
    if (args.isCurrentlyFollowing) {
      await repo.unfollowUser(args.targetUserId);
    } else {
      await repo.followUser(args.targetUserId);
    }
  },
);

class SearchRepository {
  final SupabaseClient _supabase;
  SearchRepository(this._supabase);

  Future<List<UserProfile>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final data = await _supabase
        .from('profiles')
        .select()
        .or('name.ilike.%$q%,surname.ilike.%$q%'); // Search Name OR Surname

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