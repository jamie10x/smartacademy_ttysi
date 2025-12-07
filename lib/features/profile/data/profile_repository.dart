import 'dart:io'; // Add this
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// Model
class UserProfile {
  final String id;
  final String name;
  final String surname;
  final String? avatarUrl;
  final String? bio;

  UserProfile({
    required this.id,
    required this.name,
    required this.surname,
    this.avatarUrl,
    this.bio,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      avatarUrl: map['avatar_url'],
      bio: map['bio'],
    );
  }
}

// Stats Model
class ProfileStats {
  final int followers;
  final int following;
  ProfileStats(this.followers, this.following);
}

class ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepository(this._supabase);

  // ... (getProfile, getMyProfile, updateProfile remain the same) ...
  Future<UserProfile> getProfile(String userId) async {
    final data = await _supabase.from('profiles').select().eq('id', userId).single();
    return UserProfile.fromMap(data);
  }

  Future<UserProfile> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return getProfile(user.id);
  }

  Future<void> updateProfile({required String name, required String surname, String? bio, String? avatarUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = {
      'name': name,
      'surname': surname,
      'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    };
    // Only update avatar if a new one is provided
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('profiles').update(updates).eq('id', user.id);
  }

  // --- NEW: Upload Avatar ---
  Future<String> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser!.id;
    // Overwrite existing file named 'avatar.jpg' for this user to save space
    // Or use timestamp if you want history. Let's use timestamp to avoid caching issues.
    final fileName = '${userId}_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true)
    );

    return _supabase.storage.from('avatars').getPublicUrl(fileName);
  }

  // --- NEW: Get Stats ---
  Future<ProfileStats> getStats(String userId) async {
    final followersCount = await _supabase
        .from('followers')
        .count(CountOption.exact)
        .eq('user_id', userId);

    final followingCount = await _supabase
        .from('followers')
        .count(CountOption.exact)
        .eq('follower_id', userId);

    return ProfileStats(followersCount, followingCount);
  }

  // --- NEW: Get Lists ---
  // Get people who follow ME
  Future<List<UserProfile>> getFollowers(String userId) async {
    final data = await _supabase
        .from('followers')
        .select('profiles!followers_follower_id_fkey(*)') // Select the FOLLOWER profile
        .eq('user_id', userId);

    return (data as List).map((e) => UserProfile.fromMap(e['profiles'])).toList();
  }

  // Get people I follow
  Future<List<UserProfile>> getFollowing(String userId) async {
    final data = await _supabase
        .from('followers')
        .select('profiles!followers_user_id_fkey(*)') // Select the USER profile
        .eq('follower_id', userId);

    return (data as List).map((e) => UserProfile.fromMap(e['profiles'])).toList();
  }
}

final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(profileRepositoryProvider).getMyProfile();
});

// New Provider for Stats
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if(user == null) return ProfileStats(0,0);
  return ref.read(profileRepositoryProvider).getStats(user.id);
});