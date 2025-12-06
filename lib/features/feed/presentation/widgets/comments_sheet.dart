import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/feed_repository.dart';

// Provider to fetch comments for a specific post
final commentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, postId) async {
  return ref.read(feedRepositoryProvider).getComments(postId);
});

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    try {
      await ref.read(feedRepositoryProvider).addComment(widget.postId, _controller.text.trim());
      _controller.clear();
      // Refresh the comments list
      ref.invalidate(commentsProvider(widget.postId));
      // Refresh the main feed (to update comment count)
      ref.invalidate(postsProvider);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Take up 75% of screen
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text("Izohlar (Comments)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),

          // LIST OF COMMENTS
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
              data: (comments) {
                if (comments.isEmpty) return const Center(child: Text("No comments yet. Be the first!"));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: comment.author.avatarUrl != null
                                ? NetworkImage(comment.author.avatarUrl!)
                                : null,
                            child: comment.author.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${comment.author.name} ${comment.author.surname}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                                ),
                                const SizedBox(height: 4),
                                Text(comment.content),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT FIELD
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isPosting ? null : _postComment,
                  icon: _isPosting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppTheme.primaryColor),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}