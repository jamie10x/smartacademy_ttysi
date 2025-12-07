import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../data/activity_repository.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Bidirishnomalar (Activity)")),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text("Hozircha yangilik yo'q"));
          }
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final item = activities[index];
              return ListTile(
                leading: SmartAvatar(
                  imageUrl: item.actor.avatarUrl,
                  name: item.actor.name,
                  surname: item.actor.surname,
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "${item.actor.name} ${item.actor.surname} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: _getActionText(item.type)),
                    ],
                  ),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(item.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: _getIcon(item.type),
              );
            },
          );
        },
      ),
    );
  }

  String _getActionText(String type) {
    switch (type) {
      case 'like': return "postiga like bosdi";
      case 'comment': return "postiga izoh qoldirdi";
      case 'follow': return "sizni kuzatishni boshladi";
      default: return "clicked something";
    }
  }

  Widget _getIcon(String type) {
    switch (type) {
      case 'like': return const Icon(Icons.favorite, color: Colors.red, size: 20);
      case 'comment': return const Icon(Icons.chat_bubble, color: Colors.blue, size: 20);
      case 'follow': return const Icon(Icons.person_add, color: AppTheme.primaryColor, size: 20);
      default: return const SizedBox();
    }
  }
}