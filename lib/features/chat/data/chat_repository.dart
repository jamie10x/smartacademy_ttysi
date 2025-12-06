import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(Supabase.instance.client);
});

// Model for a Chat Room
class ChatRoom {
  final String id;
  final String otherUserId; // The ID of the person you are talking to
  // Ideally we would fetch the other user's profile here too,
  // but for simplicity we will fetch it in the UI or separate call.

  ChatRoom({required this.id, required this.otherUserId});
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMine; // Helper for UI

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory Message.fromMap(Map<String, dynamic> map, String myId) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      isMine: map['sender_id'] == myId,
    );
  }
}

class ChatRepository {
  final SupabaseClient _supabase;
  ChatRepository(this._supabase);

  // 1. Start or Get existing Chat
  Future<String> createOrGetChat(String otherUserId) async {
    final myId = _supabase.auth.currentUser!.id;

    // Check if chat exists (A vs B OR B vs A)
    final existing = await _supabase.from('chats').select()
        .or('and(user_a.eq.$myId,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$myId)')
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    // Create new
    final newChat = await _supabase.from('chats').insert({
      'user_a': myId,
      'user_b': otherUserId,
    }).select().single();

    return newChat['id'];
  }

  // 2. Fetch My Chats
  Future<List<ChatRoom>> getMyChats() async {
    final myId = _supabase.auth.currentUser!.id;
    final data = await _supabase.from('chats').select();

    return (data as List).map((e) {
      // Determine which ID belongs to the "other" person
      final isUserA = e['user_a'] == myId;
      return ChatRoom(
          id: e['id'],
          otherUserId: isUserA ? e['user_b'] : e['user_a']
      );
    }).toList();
  }

  // 3. REAL-TIME Messages Stream
  Stream<List<Message>> getMessagesStream(String chatId) {
    final myId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((maps) => maps.map((e) => Message.fromMap(e, myId)).toList());
  }

  // 4. Send Message
  Future<void> sendMessage(String chatId, String content) async {
    final myId = _supabase.auth.currentUser!.id;
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'content': content,
    });
  }
}