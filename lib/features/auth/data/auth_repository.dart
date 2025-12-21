import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Provider to access this repo
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'surname': surname, // This data is picked up by our SQL Trigger!
        },
      );

      // Fallback: Manually create profile if trigger failed or didn't run (e.g. if email confirmation is off/on quirks)
      if (response.user != null) {
        await _createProfileIfNotExists(
          userId: response.user!.id,
          name: name,
          surname: surname,
          email: email,
        );
      }
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signInWithGoogle(String webClientId, String? iosClientId) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception("Sign in cancelled by user");

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception("No ID Token found.");

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Ensure profile exists after Google Login too
      if (response.user != null) {
        await _createProfileIfNotExists(
          userId: response.user!.id,
          name: response.user!.userMetadata?['name'] ?? '',
          surname:
              '', // Google doesn't always split this well, so we leave empty or try to parse
          email: response.user!.email ?? '',
        );
      }
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // --- PRIVATE HELPER TO MANUALLY CREATE PROFILE ---
  Future<void> _createProfileIfNotExists({
    required String userId,
    required String name,
    required String surname,
    required String email,
  }) async {
    // Check if exists
    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (existing != null) return;

    // Insert if not
    await _supabase.from('profiles').insert({
      'id': userId,
      'name': name,
      'surname': surname,
      'email':
          email, // Ensure your profiles table has an email column if you want to store it, otherwise remove this line
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
