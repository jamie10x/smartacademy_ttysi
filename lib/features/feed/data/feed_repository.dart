import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';

// --- ENUMS & PROVIDERS ---

enum FeedFilter { all, mine, favorites }

final feedRepositoryProvider = Provider((ref) {
  return FeedRepository(Supabase.instance.client);
});

// Update Provider to accept filter argument
final postsProvider = FutureProvider.family<List<PostModel>, FeedFilter>((
  ref,
  filter,
) async {
  return ref.read(feedRepositoryProvider).fetchPosts(filter: filter);
});

// --- MODELS ---

class PostModel {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final UserProfile author;
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

  Future<List<PostModel>> fetchPosts({
    FeedFilter filter = FeedFilter.all,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    dynamic query;

    // Base Select string
    const baseSelect = '''
      *,
      profiles:profiles!posts_author_id_fkey(*),
      post_likes(user_id),
      post_comments(id)
    ''';

    // 1. Filter Logic
    if (filter == FeedFilter.favorites) {
      // For Favorites, we need an INNER JOIN on post_likes to only get posts liked by current user
      // We explicitly state post_likes!inner to enforce the filter
      query = _supabase
          .from('posts')
          .select('''
          *,
          profiles:profiles!posts_author_id_fkey(*),
          post_likes!inner(user_id), 
          post_comments(id)
        ''')
          .eq('post_likes.user_id', userId);
    } else {
      // Standard query
      query = _supabase.from('posts').select(baseSelect);

      if (filter == FeedFilter.mine) {
        query = query.eq('author_id', userId);
      }
    }

    // 2. Ordering
    final data = await query.order('created_at', ascending: false);

    return (data as List).map((e) => PostModel.fromMap(e, userId)).toList();
  }

  // ... (Rest of the methods: toggleLike, getComments, addComment, createPost, deletePost remain unchanged)
  // Re-pasting them for completeness if you are copy-pasting the whole file:

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
    final userId = _supabase.auth.currentUser!.id;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage
        .from('post_images')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from('post_images').getPublicUrl(fileName);
  }

  Future<void> createPost(String content, File? imageFile) async {
    final userId = _supabase.auth.currentUser!.id;
    String? imageUrl;
    if (imageFile != null) imageUrl = await uploadPostImage(imageFile);
    await _supabase.from('posts').insert({
      'content': content,
      'image_url': imageUrl,
      'author_id': userId,
    });
  }

  Future<bool> deletePost(String postId) async {
    print('Attempting to delete post: $postId'); // Debug log
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: User not logged in');
        return false;
      }

      print('Current User ID: $userId');

      // Simplified delete: relies on RLS
      final response = await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .select();

      print('Delete result: $response');

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Delete error: $e'); // Log error
      return false;
    }
  }
}
