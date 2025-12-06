import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/data/profile_repository.dart';
import '../data/chat_repository.dart';

// Provider to fetch my chats
final myChatsProvider = FutureProvider((ref) => ref.read(chatRepositoryProvider).getMyChats());

// Helper provider to fetch user details for a specific chat row
final chatPartnerProvider = FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.read(profileRepositoryProvider).getProfile(userId);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Xabarlar (Messages)")),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (chats) {
          if (chats.isEmpty) return const Center(child: Text("Hozircha xabarlar yo'q"));
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Consumer(
                builder: (context, ref, _) {
                  final partnerAsync = ref.watch(chatPartnerProvider(chat.otherUserId));
                  return partnerAsync.when(
                    loading: () => const ListTile(leading: CircleAvatar(), title: Text("Loading...")),
                    error: (_,__) => const SizedBox(),
                    data: (user) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                          child: user.avatarUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text("${user.name} ${user.surname}"),
                        subtitle: const Text("Tap to chat", style: TextStyle(color: Colors.grey)),
                        onTap: () {
                          context.push('/chat/${chat.id}', extra: "${user.name} ${user.surname}");
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}