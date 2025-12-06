import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// Simple model class for UI
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

class ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepository(this._supabase);

  // Fetch specific user profile
  Future<UserProfile> getProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(data);
  }

  // Get Current User's Profile
  Future<UserProfile> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return getProfile(user.id);
  }
}

// Provider to get the current user's profile data easily in the UI
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(profileRepositoryProvider).getMyProfile();
});