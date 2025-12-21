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
  final List<String> imageUrls; // Changed from String? imageUrl
  final DateTime createdAt;
  final UserProfile author;
  final int likeCount;
  final bool isLikedByMe;
  final int commentCount;

  PostModel({
    required this.id,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.author,
    required this.likeCount,
    required this.isLikedByMe,
    required this.commentCount,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String currentUserId) {
    final likesList = (map['post_likes'] as List?) ?? [];
    final commentsList = (map['post_comments'] as List?) ?? [];

    // Parse images: prefer 'image_urls', fallback to 'image_url'
    List<String> parsedImages = [];
    if (map['image_urls'] != null) {
      parsedImages = List<String>.from(map['image_urls']);
    } else if (map['image_url'] != null) {
      parsedImages = [map['image_url']];
    }

    return PostModel(
      id: map['id'],
      content: map['content'],
      imageUrls: parsedImages,
      createdAt: DateTime.parse(map['created_at']),
      author: UserProfile.fromMap(map['profiles']),
      likeCount: likesList.length,
      isLikedByMe: likesList.any((like) => like['user_id'] == currentUserId),
      commentCount: commentsList.length,
    );
  }

  // Helper to get main image for backward compatibility if needed
  String? get firstImage => imageUrls.isNotEmpty ? imageUrls.first : null;
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

  Future<List<String>> uploadPostImages(List<File> imageFiles) async {
    final userId = _supabase.auth.currentUser!.id;
    List<String> uploadedUrls = [];

    for (var i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      await _supabase.storage
          .from('post_images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _supabase.storage.from('post_images').getPublicUrl(fileName);
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  // kept for explicit single upload if needed internally
  Future<String> uploadPostImage(File imageFile) async {
    return (await uploadPostImages([imageFile])).first;
  }

  Future<void> createPost(String content, List<File> imageFiles) async {
    final userId = _supabase.auth.currentUser!.id;

    List<String> imageUrls = [];
    if (imageFiles.isNotEmpty) {
      imageUrls = await uploadPostImages(imageFiles);
    }

    await _supabase.from('posts').insert({
      'content': content,
      'image_urls': imageUrls, // Store as array
      'image_url': imageUrls
          .firstOrNull, // Backward compatibility: store first image in old column too
      'author_id': userId,
    });
  }

  Future<bool> deletePost(String postId) async {
    print("Attempting to delete post: $postId");
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print("Delete failed: User not logged in");
        return false;
      }

      // Simplified delete: relies on RLS
      final response = await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .select();

      print("Delete response: $response");

      return (response as List).isNotEmpty;
    } catch (e) {
      print("Delete exception: $e");
      return false;
    }
  }
}
