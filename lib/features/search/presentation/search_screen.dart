import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/recent_searches_provider.dart';
import '../data/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  String _query = '';

  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setQueryDebounced(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      final next = value.trim();
      setState(() => _query = next);

      // Persist as a recent search once it looks meaningful.
      if (next.length >= 2) {
        // Fire-and-forget, provider takes care of invalidation.
        ref.read(addRecentSearchProvider(next).future);
      }
    });
  }

  void _setQueryImmediate(String value) {
    _debounce?.cancel();
    final next = value.trim();
    _searchController.text = value;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    setState(() => _query = next);

    if (next.length >= 2) {
      ref.read(addRecentSearchProvider(next).future);
    }
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchUsersProvider(_query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: _SearchField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _setQueryDebounced,
          onClear: _clearQuery,
        ),
      ),
      body: _query.isEmpty
          ? _SearchEmptyState(
              onPickQuery: (q) {
                _focusNode.unfocus();
                _setQueryImmediate(q);
              },
            )
          : searchAsync.when(
              loading: () => const _SearchLoadingState(),
              error: (err, _) => _SearchErrorState(
                errorText: err.toString(),
                onRetry: () => ref.invalidate(searchUsersProvider(_query)),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return _NoResultsState(
                    query: _query,
                    onClear: _clearQuery,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserResultCard(user: user, query: _query);
                  },
                );
              },
            ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: "Qidiruv...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.text.trim().isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.onClear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        filled: true,
        fillColor: cs.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _SearchEmptyState extends ConsumerWidget {
  const _SearchEmptyState({required this.onPickQuery});

  final ValueChanged<String> onPickQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final recentAsync = ref.watch(recentSearchesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Column(
                children: [
                  Icon(Icons.search_rounded, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "Do'stlaringizni toping",
                    style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Ism yoki familiya bo'yicha qidiring",
                    style: GoogleFonts.inter(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Recent', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(clearRecentSearchesProvider.future);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          recentAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => Text(
              'Failed to load recents',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  "No recent searches yet.",
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in items)
                    InputChip(
                      label: Text(q),
                      onPressed: () => onPickQuery(q),
                      onDeleted: () => ref.read(removeRecentSearchProvider(q).future),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.errorText, required this.onRetry});

  final String errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              'Xatolik yuz berdi',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Hech kim topilmadi',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '"$query" bo\'yicha natija yo\'q',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: const Text('Tozalash'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultCard extends ConsumerWidget {
  const _UserResultCard({required this.user, required this.query});

  final UserProfile user;
  final String query;

  Future<void> _messageUser(BuildContext context, WidgetRef ref) async {
    final chatId = await ref.read(chatRepositoryProvider).createOrGetChat(user.id);
    if (context.mounted) {
      context.push('/chat/$chatId', extra: "${user.name} ${user.surname}");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(isFollowingProvider(user.id));
    final toggleAsync = ref.watch(
      toggleFollowProvider(
        (targetUserId: user.id, isCurrentlyFollowing: followAsync.value ?? false),
      ),
    );

    final isMutating = toggleAsync.isLoading;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedName(
                      fullName: "${user.name} ${user.surname}",
                      query: query,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Message',
                icon: const Icon(Icons.message, color: AppTheme.primaryColor),
                onPressed: isMutating ? null : () => _messageUser(context, ref),
              ),
              const SizedBox(width: 6),
              followAsync.when(
                loading: () => const SizedBox(
                  width: 110,
                  height: 36,
                  child: Center(
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                error: (_, __) => SizedBox(
                  width: 110,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(isFollowingProvider(user.id)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (isFollowing) {
                  return SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isMutating
                          ? null
                          : () async {
                              final args = (targetUserId: user.id, isCurrentlyFollowing: isFollowing);
                              await ref.read(toggleFollowProvider(args).future);
                              ref.invalidate(isFollowingProvider(user.id));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey[300] : AppTheme.primaryColor,
                        foregroundColor: isFollowing ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: isMutating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isFollowing ? 'Kuzatilmoqda' : 'Kuzatish'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.fullName, required this.query});

  final String fullName;
  final String query;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    if (base == null) return Text(fullName);

    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        fullName,
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = fullName.toLowerCase();
    final lowerQ = q.toLowerCase();
    final matchIndex = lower.indexOf(lowerQ);
    if (matchIndex < 0) {
      return Text(
        fullName,
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final before = fullName.substring(0, matchIndex);
    final match = fullName.substring(matchIndex, matchIndex + q.length);
    final after = fullName.substring(matchIndex + q.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: base.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
