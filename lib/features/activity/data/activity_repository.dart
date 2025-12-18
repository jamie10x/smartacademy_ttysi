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
  final UserProfile actor;
  final String? postId;
  final String? postImageUrl; // NEW: To show the thumbnail

  ActivityModel({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.actor,
    this.postId,
    this.postImageUrl,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    // Check if 'posts' is null (e.g. for follow events)
    final postData = map['posts'];
    return ActivityModel(
      id: map['id'],
      type: map['type'],
      createdAt: DateTime.parse(map['created_at']),
      actor: UserProfile.fromMap(map['profiles']),
      postId: map['post_id'],
      postImageUrl: postData != null ? postData['image_url'] : null,
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
        .select('''
          *,
          profiles:actor_id(*),
          posts:post_id(image_url) 
        ''') // Join profiles AND posts to get the image
        .eq('user_id', myId)
        .neq('actor_id', myId)
        .order('created_at', ascending: false)
        .limit(30);

    return (data as List).map((e) => ActivityModel.fromMap(e)).toList();
  }
}