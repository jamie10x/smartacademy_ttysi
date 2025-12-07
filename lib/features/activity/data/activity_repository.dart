import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

final activityRepositoryProvider = Provider((ref) {
  return ActivityRepository(Supabase.instance.client);
});

final activitiesProvider = FutureProvider<List<ActivityModel>>((ref) async {
  return ref.read(activityRepositoryProvider).fetchActivities();
});

class ActivityModel {
  final String id;
  final String type; // 'like', 'comment', 'follow'
  final DateTime createdAt;
  final UserProfile actor; // The person who did the action
  final String? postId;

  ActivityModel({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.actor,
    this.postId,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      type: map['type'],
      createdAt: DateTime.parse(map['created_at']),
      // Join logic: actor_id points to profiles
      actor: UserProfile.fromMap(map['profiles']),
      postId: map['post_id'],
    );
  }
}

class ActivityRepository {
  final SupabaseClient _supabase;
  ActivityRepository(this._supabase);

  Future<List<ActivityModel>> fetchActivities() async {
    final myId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from('activities')
        .select('*, profiles:actor_id(*)') // Join to get Actor details
        .eq('user_id', myId) // Only my notifications
        .neq('actor_id', myId) // Don't show "I liked my own post"
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List).map((e) => ActivityModel.fromMap(e)).toList();
  }
}