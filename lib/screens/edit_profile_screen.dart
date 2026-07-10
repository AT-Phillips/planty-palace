import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/photo_storage_service.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/inset_group.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUploadingPhoto = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.instance.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    await AuthService.instance.updateProfile(
      displayName: _nameController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Name updated')));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final uid = AuthService.instance.currentUser!.uid;
      final photoUrl = await PhotoStorageService().uploadProfilePhoto(
        uid,
        File(picked.path),
      );
      await AuthService.instance.updateProfile(photoUrl: photoUrl);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _selectPreset(int index) async {
    await AuthService.instance.updateProfile(
      photoUrl: presetAvatarValue(index),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign in with $provider is coming soon.')),
    );
  }

  Future<void> _upgrade() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await AuthService.instance.upgradeToEmailAccount(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Change Password'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: currentController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                        ),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await AuthService.instance.changePassword(
                            currentController.text,
                            newController.text,
                          );
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (e) {
                          setDialogState(() => dialogError = e.toString());
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final isEmailAccount =
        !AuthService.instance.isAnonymous && AuthService.instance.email != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes every Space, plant, propagation, and photo tied to '
                  'this account. This cannot be undone.',
                ),
                if (isEmailAccount) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm your password',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.deleteAccount(
        currentPassword: isEmailAccount ? passwordController.text : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  Widget _avatarSection() {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _isUploadingPhoto
                ? const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator.adaptive(),
                )
                : ProfileAvatar(
                  photoUrl: AuthService.instance.photoUrl,
                  size: 96,
                ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Or choose an icon',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < presetAvatarIcons.length; i++)
                  GestureDetector(
                    onTap: () => _selectPreset(i),
                    child: ProfileAvatar(
                      photoUrl: presetAvatarValue(i),
                      size: 44,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.check), onPressed: _saveName),
          ],
        ),
      ),
    );
  }

  Widget _anonymousSection() {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Save your account with an email and password so you can recover your Gardens '
              'and plants on a new device or after reinstalling.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _upgrade,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Save my account'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showComingSoon('Apple'),
                    child: const Text('Apple'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showComingSoon('Google'),
                    child: const Text('Google'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showComingSoon('Facebook'),
                    child: const Text('Facebook'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountManagementSection() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetGroup(
          dividerIndent: 56,
          children: [
            if (AuthService.instance.email != null)
              InsetRow(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _changePassword,
              ),
            InsetRow(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: _signOut,
              showChevron: false,
            ),
          ],
        ),
        InsetGroup(
          children: [
            InsetRow(
              icon: Icons.delete_forever_outlined,
              iconColor: scheme.error,
              title: 'Delete Account',
              titleColor: scheme.error,
              showChevron: false,
              onTap: _isSubmitting ? null : _deleteAccount,
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = AuthService.instance.isAnonymous;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Edit Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _avatarSection(),
          const SizedBox(height: 12),
          _nameSection(),
          const SizedBox(height: 12),
          if (isAnonymous) _anonymousSection() else _accountManagementSection(),
        ],
      ),
    );
  }
}
