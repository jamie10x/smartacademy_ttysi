import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../profile/data/profile_repository.dart';
import '../data/chat_repository.dart';

final myChatsProvider = FutureProvider((ref) => ref.read(chatRepositoryProvider).getMyChats());

final chatPartnerProvider = FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.read(profileRepositoryProvider).getProfile(userId);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      appBar: AppBar(
        title: const Text("Kontaktlar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  suffixIcon: const Icon(Icons.edit, color: Colors.black, size: 20),
                  border: InputBorder.none,
                  hintText: "",
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // White Card Container for List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: chatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (chats) {
                  if (chats.isEmpty) return const Center(child: Text("Hozircha xabarlar yo'q"));

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Consumer(
                        builder: (context, ref, _) {
                          final partnerAsync = ref.watch(chatPartnerProvider(chat.otherUserId));
                          return partnerAsync.when(
                            loading: () => const SizedBox(),
                            error: (_,__) => const SizedBox(),
                            data: (user) {
                              return InkWell(
                                onTap: () => context.push('/chat/${chat.id}', extra: "${user.name} ${user.surname}"),
                                child: Row(
                                  children: [
                                    SmartAvatar(
                                      imageUrl: user.avatarUrl,
                                      name: user.name,
                                      surname: user.surname,
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name, // Just first name as per design usually, or full
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "email@gmail.com", // Mock email or bio for now
                                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}