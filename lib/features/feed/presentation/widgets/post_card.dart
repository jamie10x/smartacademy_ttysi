import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/feed_repository.dart';
import 'comments_sheet.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAgo = DateFormat.yMMMd().format(post.createdAt);
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isMyPost = myId == post.author.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Avatar + Name + More Options)
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
              Expanded(
                child: Column(
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
              ),
              if (isMyPost)
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text("Delete", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    )
                  ],
                )
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
                  await ref.read(feedRepositoryProvider).toggleLike(post.id, post.isLikedByMe);
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
                    isScrollControlled: true,
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await ref.read(feedRepositoryProvider).deletePost(post.id);
              ref.invalidate(postsProvider); // Refresh feed
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}