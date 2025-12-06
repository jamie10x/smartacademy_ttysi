import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add Riverpod
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/feed_repository.dart';
import 'comments_sheet.dart';

// Change to ConsumerWidget to access providers
class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAgo = DateFormat.yMMMd().format(post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Name)
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage: post.author.avatarUrl != null
                    ? NetworkImage(post.author.avatarUrl!)
                    : null,
                child: post.author.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${post.author.name} ${post.author.surname}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(post.content, style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),

          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            ),

          // --- ACTION BUTTONS ---
          Row(
            children: [
              // LIKE BUTTON
              InkWell(
                onTap: () async {
                  // 1. Call API
                  await ref.read(feedRepositoryProvider).toggleLike(post.id, post.isLikedByMe);
                  // 2. Refresh List to show updated count/color
                  ref.invalidate(postsProvider);
                },
                child: Row(
                  children: [
                    Icon(
                      post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.isLikedByMe ? Colors.red : Colors.black87,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text("${post.likeCount} likes", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // COMMENT BUTTON
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Allow full height
                    builder: (context) => CommentsSheet(postId: post.id),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 22),
                    const SizedBox(width: 6),
                    Text("${post.commentCount} comments", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}