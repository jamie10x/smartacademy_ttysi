import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../feed/data/feed_repository.dart';
import '../../feed/presentation/widgets/post_card.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final myPostsAsync = ref.watch(postsProvider(FeedFilter.mine));

    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header & Profile Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Settings Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Profil",
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.black54,
                              ),
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Premium Identity Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF002F87), Color(0xFF001A4D)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF002F87,
                                ).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white30,
                                    width: 2,
                                  ),
                                ),
                                child: SmartAvatar(
                                  imageUrl: profile.avatarUrl,
                                  name: profile.name,
                                  surname: profile.surname,
                                  radius: 45,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${profile.name} ${profile.surname}",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => context.push(
                                      '/edit-profile',
                                      extra: profile,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (profile.bio != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  profile.bio!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              Divider(color: Colors.white24),
                              const SizedBox(height: 16),

                              // Stats
                              statsAsync.when(
                                loading: () => const SizedBox(),
                                error: (e, _) => const SizedBox(),
                                data: (stats) => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn(
                                      count: stats.followers.toString(),
                                      label: "Obunachilar",
                                      onTap: () => context.push(
                                        '/follow-list/followers',
                                      ),
                                    ),
                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: Colors.white24,
                                    ),
                                    _buildStatColumn(
                                      count: stats.following.toString(),
                                      label: "Obunalar",
                                      onTap: () => context.push(
                                        '/follow-list/following',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),

                // 2. Recent Posts Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Mening Postlarim",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Recent Posts List
                myPostsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text("Error: $e")),
                  ),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.feed_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Hozircha postlar yo'q",
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = posts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          // Reuse PostCard but with a slight elevation or border if needed
                          // The PostCard itself has margin bottom, so we just wrap it.
                          child: PostCard(post: post),
                        );
                      }, childCount: posts.length),
                    );
                  },
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ), // Bottom padding
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
