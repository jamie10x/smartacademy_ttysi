import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/feed_repository.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateFormat.yMMMd().format(post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Time
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
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),

          const SizedBox(height: 12),

          // Content Text
          Text(
            post.content,
            style: GoogleFonts.inter(fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 12),

          // Optional Image
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => const SizedBox(),
              ),
            ),

          if (post.imageUrl != null) const SizedBox(height: 12),

          // Action Buttons (Mocked for now)
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 20),
              const SizedBox(width: 6),
              const Text("12 likes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),

              const SizedBox(width: 20),

              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 6),
              const Text("4 comments", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}