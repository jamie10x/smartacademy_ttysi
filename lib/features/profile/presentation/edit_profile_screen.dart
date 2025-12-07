import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/presentation/widgets/smart_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../data/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _bioController;
  File? _newAvatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _surnameController = TextEditingController(text: widget.user.surname);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  // Logic to open Gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newAvatarFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl;

      // 1. Upload Image if user picked a new one
      if (_newAvatarFile != null) {
        newAvatarUrl = await ref.read(profileRepositoryProvider).uploadAvatar(_newAvatarFile!);
      }

      // 2. Update Profile Data
      await ref.read(profileRepositoryProvider).updateProfile(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      // 3. Refresh the profile screen
      ref.invalidate(myProfileProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilni tahrirlash"),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, color: AppTheme.primaryColor),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- IMAGE PICKER SECTION ---
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Stack(
                  children: [
                    // Show New Image (File) OR Old Image (Network)
                    _newAvatarFile != null
                        ? CircleAvatar(radius: 50, backgroundImage: FileImage(_newAvatarFile!))
                        : SmartAvatar(
                      imageUrl: widget.user.avatarUrl,
                      name: widget.user.name,
                      surname: widget.user.surname,
                      radius: 50,
                    ),

                    // Camera Icon Overlay
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Rasmni o'zgartirish", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            // --- TEXT FIELDS ---
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Ism", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _surnameController, decoration: const InputDecoration(labelText: "Familiya", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: "Bio (Ixtiyoriy)", border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}