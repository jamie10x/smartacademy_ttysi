import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final statsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF002F87), // University Blue
              Color(0xFF001A4D), // Darker shade
            ],
          ),
        ),
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (profile) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Header with Settings
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white70,
                          ),
                          onPressed: () => context.push('/settings'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Glassmorph Card for Profile Info
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar with Glow
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: SmartAvatar(
                                imageUrl: profile.avatarUrl,
                                name: profile.name,
                                surname: profile.surname,
                                radius: 50,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name & Edit Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${profile.name} ${profile.surname}",
                                  style: GoogleFonts.outfit(
                                    // Using Outfit for modern look if available, mostly likely falls back or looks clean
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
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (profile.bio != null)
                              Text(
                                profile.bio!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Stats Row inside Card
                            statsAsync.when(
                              loading: () => const LinearProgressIndicator(
                                color: Colors.white10,
                              ),
                              error: (e, _) => const SizedBox(),
                              data: (stats) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(
                                    count: stats.followers.toString(),
                                    label: "Obunachilar",
                                    onTap: () =>
                                        context.push('/follow-list/followers'),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildStatColumn(
                                    count: stats.following.toString(),
                                    label: "Obunalar",
                                    onTap: () =>
                                        context.push('/follow-list/following'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Decorative Element or Additional Info
                      const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: Colors.white10,
                      ),
                      Text(
                        "TTYSI Social",
                        style: GoogleFonts.inter(
                          color: Colors.white10,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
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
