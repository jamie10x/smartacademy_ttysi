import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../presentation/main_scaffold.dart';

// Create simple placeholders for other tabs so app doesn't crash
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = Supabase.instance.client.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/signup';

      if (session == null && !isLoggingIn) return '/login';
      if (session != null && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

      // THE SHELL ROUTE (Tab Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/home',
                  builder: (context, state) => const FeedScreen()
              ),
            ],
          ),
          // Tab 2: Search
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (context, state) => const PlaceholderScreen("Search")),
            ],
          ),
          // Tab 3: Create
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/create', builder: (context, state) => const PlaceholderScreen("Create Post")),
            ],
          ),
          // Tab 4: Activity
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/activity', builder: (context, state) => const PlaceholderScreen("Activity")),
            ],
          ),
          // Tab 5: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}