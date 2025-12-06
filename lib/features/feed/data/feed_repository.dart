import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

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
    final likesList = (map['post_likes'] as List?) ?? [];
    final commentsList = (map['post_comments'] as List?) ?? [];

    return PostModel(
      id: map['id'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
      // The alias 'profiles' ensures this key still works
      author: UserProfile.fromMap(map['profiles']),
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

  Future<List<PostModel>> fetchPosts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // FIX APPLIED HERE:
    // We use 'profiles:profiles!posts_author_id_fkey(*)'
    // 1. 'profiles:' -> This tells Supabase to name the JSON key "profiles" (so our Model works)
    // 2. '!posts_author_id_fkey' -> This tells Supabase to specifically use the Author relationship, not the Likes relationship.
    final data = await _supabase
        .from('posts')
        .select('''
          *,
          profiles:profiles!posts_author_id_fkey(*),
          post_likes(user_id),
          post_comments(id)
        ''')
        .order('created_at', ascending: false);

    return (data as List).map((e) => PostModel.fromMap(e, userId)).toList();
  }

  Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    final userId = _supabase.auth.currentUser!.id;
    if (isCurrentlyLiked) {
      await _supabase.from('post_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _supabase
        .from('post_comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => CommentModel.fromMap(e)).toList();
  }

  Future<void> addComment(String postId, String text) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'author_id': userId,
      'content': text,
    });
  }

  Future<String> uploadPostImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('post_images').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      return _supabase.storage.from('post_images').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> createPost(String content, File? imageFile) async {
    final userId = _supabase.auth.currentUser!.id;
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await uploadPostImage(imageFile);
    }

    await _supabase.from('posts').insert({
      'content': content,
      'image_url': imageUrl,
      'author_id': userId,
    });
  }

  Future<void> deletePost(String postId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('posts').delete().match({
      'id': postId,
      'author_id': userId,
    });
  }
}