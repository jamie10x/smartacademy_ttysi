import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Router handles redirection automatically
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    try {
      // 1. Setup Google Sign In
      // NOTE: serverClientId is actually your WEB Client ID from Google Cloud Console
      const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

      // 2. iOS requires the clientId (iOS specific one from Cloud Console)
      // Android requires the serverClientId (The Web one)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      // 3. Trigger the popup
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the login
        return;
      }

      // 4. Get the tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // 5. Send to Supabase
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Router will handle the redirection to Home automatically

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002F87),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo Placeholder
              const Icon(Icons.shield, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                "Toshkent to'qimachilik\nva yengil sanoat\ninstituti",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Inputs
              _buildTextField(_emailController, "email@gmail.com", false),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, "Parol", true),

              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF002F87),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Davom etish", style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // Divider
              const Row(children: [
                Expanded(child: Divider(color: Colors.white54)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("yoki", style: TextStyle(color: Colors.white)),
                ),
                Expanded(child: Divider(color: Colors.white54)),
              ]),

              const SizedBox(height: 20),

              // Google Button (Mock)
              OutlinedButton.icon(
                onPressed: _googleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text("Google bilan davom eting"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 40),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text(
                  "Akkauntingiz yo'qmi? Unda ro'yxatdan o'ting",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}