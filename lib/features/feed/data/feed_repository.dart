import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

// --- PROVIDERS ---

final feedRepositoryProvider = Provider((ref) {
  return FeedRepository(Supabase.instance.client);
});

final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.read(feedRepositoryProvider).fetchPosts();
});

// --- MODELS ---

class PostModel {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final UserProfile author;

  // Social Stats
  final int likeCount;
  final bool isLikedByMe;
  final int commentCount;

  PostModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.author,
    required this.likeCount,
    required this.isLikedByMe,
    required this.commentCount,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String currentUserId) {
    // Supabase returns joined tables as lists of objects
    final likesList = (map['post_likes'] as List?) ?? [];
    final commentsList = (map['post_comments'] as List?) ?? [];

    return PostModel(
      id: map['id'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
      // The 'profiles' key contains the author data due to the join
      author: UserProfile.fromMap(map['profiles']),

      // Calculate stats based on the returned lists
      likeCount: likesList.length,
      isLikedByMe: likesList.any((like) => like['user_id'] == currentUserId),
      commentCount: commentsList.length,
    );
  }
}

class CommentModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final UserProfile author;

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      author: UserProfile.fromMap(map['profiles']),
    );
  }
}

// --- REPOSITORY ---

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  /// 1. Fetch Posts with Join (Author, Likes, Comments)
  Future<List<PostModel>> fetchPosts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('posts')
        .select('''
          *,
          profiles(*),
          post_likes(user_id),
          post_comments(id)
        ''')
        .order('created_at', ascending: false);

    return (data as List).map((e) => PostModel.fromMap(e, userId)).toList();
  }

  /// 2. Like or Unlike a Post
  Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    final userId = _supabase.auth.currentUser!.id;

    if (isCurrentlyLiked) {
      // Unlike: Remove the row
      await _supabase.from('post_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      // Like: Add a row
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  /// 3. Fetch Comments for a specific Post
  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _supabase
        .from('post_comments')
        .select('*, profiles(*)') // Join with profiles to get author name/avatar
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => CommentModel.fromMap(e)).toList();
  }

  /// 4. Add a new Comment
  Future<void> addComment(String postId, String text) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'author_id': userId,
      'content': text,
    });
  }

  /// 5. Upload Image to Storage
  Future<String> uploadPostImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Create unique filename: userID_timestamp.jpg
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('post_images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('post_images').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// 6. Create a New Post
  Future<void> createPost(String content, File? imageFile) async {
    final userId = _supabase.auth.currentUser!.id;
    String? imageUrl;

    // Upload image first if it exists
    if (imageFile != null) {
      imageUrl = await uploadPostImage(imageFile);
    }

    // Insert post data
    await _supabase.from('posts').insert({
      'content': content,
      'image_url': imageUrl,
      'author_id': userId,
    });
  }
}