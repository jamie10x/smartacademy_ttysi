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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Yangiliklar",
            style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Barchasi"),
              Tab(text: "Siz joylaganlar"),
              Tab(text: "Sevimlilar"),
            ],
          ),
          actions: [
            IconButton(
                onPressed: (){},
                icon: const Icon(Icons.notifications_none, color: Colors.black87)
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _PostList(filter: FeedFilter.all),
            _PostList(filter: FeedFilter.mine),
            _PostList(filter: FeedFilter.favorites),
          ],
        ),
      ),
    );
  }
}

class _PostList extends ConsumerWidget {
  final FeedFilter filter;
  const _PostList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific provider based on the filter
    final postsAsync = ref.watch(postsProvider(filter));

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (posts) {
        if (posts.isEmpty) {
          String message = "Yangiliklar yo'q";
          IconData icon = Icons.feed_outlined;

          if (filter == FeedFilter.mine) {
            message = "Siz hali post joylamadingiz";
            icon = Icons.post_add;
          }
          if (filter == FeedFilter.favorites) {
            message = "Sevimli postlar yo'q";
            icon = Icons.favorite_border;
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(message, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(postsProvider(filter)),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          ),
        );
      },
    );
  }
}