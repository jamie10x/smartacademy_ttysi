import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

final feedRepositoryProvider = Provider((ref) {
  return FeedRepository(Supabase.instance.client);
});

final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.read(feedRepositoryProvider).fetchPosts();
});

class PostModel {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final UserProfile author;

  PostModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.author,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
      // Supabase returns the joined table data in a key named 'profiles'
      author: UserProfile.fromMap(map['profiles']),
    );
  }
}

class FeedRepository {
  final SupabaseClient _supabase;
  FeedRepository(this._supabase);

  Future<List<PostModel>> fetchPosts() async {
    final data = await _supabase
        .from('posts')
        .select('*, profiles(*)') // <--- The Magic Join
        .order('created_at', ascending: false); // Newest first

    return (data as List).map((e) => PostModel.fromMap(e)).toList();
  }
}