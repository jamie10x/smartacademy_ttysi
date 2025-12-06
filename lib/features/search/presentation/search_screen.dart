import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchUsersProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _query = val);
          },
          decoration: InputDecoration(
            hintText: "Qidiruv... (Search user)",
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Do'stlaringizni toping", style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      )
          : searchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text("Hech kim topilmadi"));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserListTile(user: user);
            },
          );
        },
      ),
    );
  }
}

class _UserListTile extends ConsumerStatefulWidget {
  final UserProfile user;
  const _UserListTile({required this.user});

  @override
  ConsumerState<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends ConsumerState<_UserListTile> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final status = await ref.read(searchRepositoryProvider).isFollowing(widget.user.id);
    if (mounted) {
      setState(() {
      _isFollowing = status;
      _isLoading = false;
    });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final repo = ref.read(searchRepositoryProvider);
    if (_isFollowing) {
      await repo.unfollowUser(widget.user.id);
    } else {
      await repo.followUser(widget.user.id);
    }
    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoading = false;
      });
    }
  }

  Future<void> _messageUser() async {
    final chatId = await ref.read(chatRepositoryProvider).createOrGetChat(widget.user.id);
    if (mounted) {
      context.push('/chat/$chatId', extra: "${widget.user.name} ${widget.user.surname}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.user.avatarUrl != null ? NetworkImage(widget.user.avatarUrl!) : null,
        child: widget.user.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text("${widget.user.name} ${widget.user.surname}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.message, color: AppTheme.primaryColor),
            onPressed: _messageUser,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? Colors.grey[300] : AppTheme.primaryColor,
              foregroundColor: _isFollowing ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isFollowing ? "Kuzatilmoqda" : "Kuzatish"),
          ),
        ],
      ),
    );
  }
}