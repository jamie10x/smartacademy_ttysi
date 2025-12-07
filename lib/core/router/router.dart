import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/activity/presentation/activity_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/feed/presentation/create_post_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/follow_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../presentation/main_scaffold.dart';

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
      GoRoute(path: '/report', builder: (context, state) => const ReportScreen()),

      // Edit Profile Route
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final user = state.extra as UserProfile;
          return EditProfileScreen(user: user);
        },
      ),

      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final userName = state.extra as String? ?? "Chat";
          return ChatScreen(chatId: id, otherUserName: userName);
        },
      ),

      GoRoute(
        path: '/follow-list/:type', // type = followers OR following
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return FollowListScreen(type: type);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const FeedScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/create', builder: (context, state) => const CreatePostScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/activity', builder: (context, state) => const ActivityScreen()),
            ],
          ),
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