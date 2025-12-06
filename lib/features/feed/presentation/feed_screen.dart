import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartacademy_ttysi/features/feed/presentation/widgets/post_card.dart';

import '../../../core/theme/app_theme.dart';
import '../data/feed_repository.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Yangiliklar",
          style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text("Hozircha yangiliklar yo'q (No posts yet)"));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(postsProvider),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}