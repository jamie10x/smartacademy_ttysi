import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/feed_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _cancelRequested = false;

  static const int _maxChars = 500;

  String get _trimmedText => _contentController.text.trim();

  bool get _hasDraft {
    return _trimmedText.isNotEmpty || _selectedImages.isNotEmpty;
  }

  bool get _canPost {
    if (_isLoading) return false;
    // Allow text-only OR image-only OR both.
    return _trimmedText.isNotEmpty || _selectedImages.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isLoading) return;

    final picker = ImagePicker();
    try {
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);

      if (pickedFiles.isEmpty) return;

      final newFiles = pickedFiles.map((e) => File(e.path)).toList();

      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(newFiles);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick images: $e')));
    }
  }

  Future<bool> _confirmDiscardDraft() async {
    if (!_hasDraft) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'Your post will be lost if you leave this screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _handlePop() async {
    if (_isLoading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Posting... please wait')));
      return false;
    }
    return _confirmDiscardDraft();
  }

  Future<void> _maybeExit() async {
    if (await _handlePop()) {
      if (!mounted) return;
      final didPop = await Navigator.of(context).maybePop();
      if (!didPop && mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_canPost) return;

    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
      _cancelRequested = false;
    });

    try {
      if (_cancelRequested) return;

      await ref
          .read(feedRepositoryProvider)
          .createPost(_trimmedText, _selectedImages);

      if (!mounted || _cancelRequested) return;

      _contentController.clear();
      setState(() => _selectedImages.clear());

      ref.invalidate(postsProvider(FeedFilter.all));
      ref.invalidate(postsProvider(FeedFilter.mine));

      context.go('/home');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _cancelRequested = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textLen = _trimmedText.length;
    final remaining = _maxChars - _contentController.text.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _maybeExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: _maybeExit,
          ),
          actions: [
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => setState(() => _cancelRequested = true),
                  child: const Text('Cancel'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _canPost ? _submitPost : null,
                  child: const Text('Post'),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: cs.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            children: [
                              TextField(
                                controller: _contentController,
                                focusNode: _focusNode,
                                maxLines: null,
                                minLines: 4,
                                maxLength: _maxChars,
                                enabled: !_isLoading,
                                textInputAction: TextInputAction.newline,
                                onChanged: (_) {
                                  if (!mounted) return;
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: "What's happening at TTYESI?",
                                  border: InputBorder.none,
                                  counterText: '',
                                  helperText:
                                      _selectedImages.isEmpty &&
                                          _trimmedText.isEmpty
                                      ? 'Write something or add photos to post.'
                                      : null,
                                  helperStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.outline),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$textLen/$_maxChars'
                                      '${remaining <= 50 ? ' • $remaining left' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: remaining < 0
                                                ? cs.error
                                                : cs.outline,
                                          ),
                                    ),
                                  ),
                                  if (_trimmedText.isNotEmpty && !_isLoading)
                                    TextButton.icon(
                                      onPressed: () {
                                        _contentController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.backspace_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Clear'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 120, // Height for horizontal scrolling list
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return _ImagePreview(
                                file: _selectedImages[index],
                                onRemove: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                              );
                            },
                          ),
                        ),

                      if (_selectedImages.isNotEmpty)
                        const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? _pickImages
                              : _pickImages, // Allow picking more even if some selected
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            _selectedImages.isEmpty
                                ? 'Add photos'
                                : 'Add more photos',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      if (!_canPost)
                        Text(
                          'Add text or valid photos to enable posting.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: cs.outline),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: cs.surface.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Material(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  _cancelRequested ? 'Cancelling…' : 'Posting…',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _cancelRequested
                                      ? 'We\'ll stop once the current step finishes.'
                                      : 'Uploading ${_selectedImages.length} images...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: cs.outline),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _cancelRequested
                                        ? null
                                        : () => setState(
                                            () => _cancelRequested = true,
                                          ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, required this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120, // thumbnail width
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 24),
                );
              },
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
