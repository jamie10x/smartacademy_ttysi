import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../../core/presentation/widgets/smart_image.dart';
import '../data/activity_repository.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bildirishnomalar",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF), // Bright Blue
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Yangiliklar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

            // List
            Expanded(
              child: activityAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (activities) {
                  if (activities.isEmpty) {
                    return const Center(child: Text("Hozircha yangilik yo'q"));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activities.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final item = activities[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Red Dot (Mock for unread)
                          Container(
                            margin: const EdgeInsets.only(top: 15, right: 8),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),

                          // Avatar
                          SmartAvatar(
                            imageUrl: item.actor.avatarUrl,
                            name: item.actor.name,
                            surname: item.actor.surname,
                            radius: 24,
                          ),
                          const SizedBox(width: 12),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(color: Colors.black, fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: "${item.actor.name} ${item.actor.surname} ", // Username in bold is confusing in design, sticking to name
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: _getTimeAgo(item.createdAt),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getActionText(item.type),
                                  style: GoogleFonts.inter(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),

                          // Right Side Action (Button or Image)
                          if (item.type == 'follow')
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2962FF),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                elevation: 0,
                              ),
                              child: const Text("Kuzatish", style: TextStyle(fontSize: 12)),
                            )
                          else if (item.postImageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SmartImage(
                                item.postImageUrl!,
                                width: 44,
                                height: 44,
                              ),
                            )
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionText(String type) {
    switch (type) {
      case 'like': return "Sizning po'stingiz yoqdi";
      case 'comment': return "Sizning postingizga fikr bildirdi";
      case 'follow': return "Sizni kuzatishni boshladi";
      default: return "";
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    return "${diff.inMinutes}m";
  }
}