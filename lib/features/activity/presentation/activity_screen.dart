import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../../core/presentation/widgets/smart_image.dart';
import '../data/activity_repository.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int _selectedTab = 0;

  // Tabs are local UI categories; "posts" depends on how your backend encodes it.
  // If your API uses a different type for "new post", update the predicate below.
  late final List<_ActivityTab> _tabs = [
    _ActivityTab(
      label: 'Barchasi',
      icon: Icons.notifications_none,
      predicate: (_) => true,
      typeKeys: const {},
    ),
    _ActivityTab(
      label: 'Layklar',
      icon: Icons.favorite_border,
      predicate: (a) => a.type == 'like',
      typeKeys: const {'like'},
    ),
    _ActivityTab(
      label: 'Izohlar',
      icon: Icons.mode_comment_outlined,
      predicate: (a) => a.type == 'comment',
      typeKeys: const {'comment'},
    ),
    _ActivityTab(
      label: 'Kuzatuvchilar',
      icon: Icons.person_add_alt_1_outlined,
      predicate: (a) => a.type == 'follow',
      typeKeys: const {'follow'},
    ),
    _ActivityTab(
      label: 'Postlar',
      icon: Icons.article_outlined,
      // Heuristic: treat explicit "post" type OR anything that has postImageUrl but isn't like/comment/follow.
      predicate: (a) => a.type == 'post' || (a.postImageUrl != null && a.type != 'like' && a.type != 'comment' && a.type != 'follow'),
      typeKeys: const {'post'},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true, // <-- center AppBar title
        title: activityAsync.maybeWhen(
          data: (activities) {
            final total = activities.length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Bildirishnomalar",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(width: 8),
                  _CountBadge(count: total, selected: true),
                ],
              ],
            );
          },
          orElse: () => Text(
            "Bildirishnomalar",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: activityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
          data: (activities) {
            final counts = _countByTabs(activities);

            final clamped = _selectedTab.clamp(0, _tabs.length - 1);
            if (clamped != _selectedTab) _selectedTab = clamped;

            final filtered = activities.where(_tabs[_selectedTab].predicate).toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activitiesProvider);
                await ref.read(activitiesProvider.future);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs / categories with counts
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tabs.length, (i) {
                          final tab = _tabs[i];
                          final selected = i == _selectedTab;
                          final count = counts[i] ?? 0;

                          return Padding(
                            padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setState(() => _selectedTab = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF2962FF) : const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab.icon,
                                      size: 18,
                                      color: selected ? Colors.white : Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tab.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: 8),
                                      _CountBadge(
                                        count: count,
                                        selected: selected,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  Expanded(
                    child: filtered.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              // Center empty-state info on screen while still allowing pull-to-refresh.
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey[400]),
                                          const SizedBox(height: 12),
                                          Text(
                                            "Hozircha yangilik yo'q",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Yangilash uchun pastga torting",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Unread indicator (still mock)
                                  Container(
                                    margin: const EdgeInsets.only(top: 15, right: 8),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  SmartAvatar(
                                    imageUrl: item.actor.avatarUrl,
                                    name: item.actor.name,
                                    surname: item.actor.surname,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.inter(color: Colors.black, fontSize: 14),
                                            children: [
                                              TextSpan(
                                                text: "${item.actor.name} ${item.actor.surname} ",
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

                                  if (item.type == 'follow')
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2962FF),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(88, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text("Kuzatish", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    )
                                  else if (item.postImageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SmartImage(
                                        item.postImageUrl!,
                                        width: 44,
                                        height: 44,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<int, int> _countByTabs(List activities) {
    final counts = <int, int>{};
    for (var i = 0; i < _tabs.length; i++) {
      counts[i] = activities.where(_tabs[i].predicate).length;
    }
    return counts;
  }

  String _getActionText(String type) {
    switch (type) {
      case 'like':
        return "Sizning po'stingiz yoqdi";
      case 'comment':
        return "Sizning postingizga fikr bildirdi";
      case 'follow':
        return "Sizni kuzatishni boshladi";
      case 'post':
        return "Yangi post joyladi";
      default:
        return "";
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    final m = diff.inMinutes;
    return "${m <= 0 ? 1 : m}m";
  }
}

class _ActivityTab {
  const _ActivityTab({
    required this.label,
    required this.icon,
    required this.predicate,
    required this.typeKeys,
  });

  final String label;
  final IconData icon;
  final bool Function(dynamic activity) predicate;

  // Optional: reserved for future if you add backend-provided unread counts per type.
  final Set<String> typeKeys;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // When used in AppBar we want a subtle pill; keep readable.
        color: selected ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}

