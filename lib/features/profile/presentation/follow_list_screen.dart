import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../data/profile_repository.dart';

// Provider family to fetch the correct list
final followListProvider = FutureProvider.family<List<UserProfile>, String>((ref, type) async {
  final repo = ref.read(profileRepositoryProvider);
  final user = ref.read(myProfileProvider).value!;

  if (type == 'followers') {
    return repo.getFollowers(user.id);
  } else {
    return repo.getFollowing(user.id);
  }
});

class FollowListScreen extends ConsumerWidget {
  final String type; // 'followers' or 'following'

  const FollowListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(followListProvider(type));
    final title = type == 'followers' ? "Kuzatayotganlar (Followers)" : "Kuzatish (Following)";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text("Ro'yxat bo'sh"));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: SmartAvatar(imageUrl: user.avatarUrl, name: user.name, surname: user.surname),
                title: Text("${user.name} ${user.surname}"),
              );
            },
          );
        },
      ),
    );
  }
}