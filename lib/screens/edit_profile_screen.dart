import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/photo_storage_service.dart';
import '../styles/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/inset_group.dart';
import '../widgets/primitives.dart';
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

  // --- Photo / avatar -------------------------------------------------------

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    try {
      await AuthService.instance.updateProfile(
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      showAppSnack(context, 'Name updated');
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, authErrorMessage(e), error: true);
    }
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
      debugPrint('Profile photo upload failed: $e');
      if (!mounted) return;
      showAppSnack(
        context,
        "Couldn't update your photo. Check your connection and try again.",
        error: true,
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
    showAppSnack(context, 'Sign in with $provider is coming soon.');
  }

  // --- Account --------------------------------------------------------------

  /// Validates locally before spending a network round trip, so the common
  /// mistakes (empty field, obvious typo, short password) are caught
  /// instantly instead of coming back as a Firebase error code.
  String? _validateCredentials() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) return 'Enter an email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That email address does not look right.';
    }
    if (password.length < 6) {
      return 'Pick a password at least 6 characters long.';
    }
    return null;
  }

  Future<void> _upgrade() async {
    FocusScope.of(context).unfocus();
    final validationError = _validateCredentials();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

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
      showAppSnack(context, 'Account saved. Your plants are backed up.');
    } catch (e) {
      debugPrint('Account upgrade failed: $e');
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Sign out?',
      message:
          'You can sign back in anytime with your email and password to get '
          'your plants back.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      showAppSnack(context, 'Password updated');
    }
  }

  Future<void> _deleteAccount() async {
    final isEmailAccount =
        !AuthService.instance.isAnonymous && AuthService.instance.email != null;

    // Deleting an account is irreversible and wipes every plant, so it takes
    // two deliberate steps: confirm the consequence, then (for a real
    // account) re-enter the password.
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete account?',
      message:
          'This permanently deletes every Space, plant, propagation, and '
          'photo tied to this account. It cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    String? password;
    if (isEmailAccount) {
      password = await showAppPrompt(
        context,
        title: 'Confirm your password',
        hintText: 'Password',
        confirmLabel: 'Delete account',
      );
      if (password == null || !mounted) return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.deleteAccount(currentPassword: password);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = authErrorMessage(e);
      });
    }
  }

  // --- Sections -------------------------------------------------------------

  Widget _avatarSection() {
    final p = context.palette;
    final currentPhoto = AuthService.instance.photoUrl;
    final selectedPreset = presetAvatarIndex(currentPhoto);

    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child:
                _isUploadingPhoto
                    ? const Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                    : ProfileAvatar(photoUrl: currentPhoto, size: 104),
          ),
          Gap.lg,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                  onPressed: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
          Gap.lg,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'OR CHOOSE AN ICON',
              style: AppTheme.sectionLabelStyle(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < presetAvatarIcons.length; i++)
                GestureDetector(
                  onTap: () => _selectPreset(i),
                  // The selected icon gets a fern ring - previously there was
                  // no indication of which preset was in use.
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selectedPreset == i ? p.fern : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ProfileAvatar(
                      photoUrl: presetAvatarValue(i),
                      size: 42,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nameSection() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveName(),
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
          ),
          const SizedBox(width: 10),
          CircleAction(
            icon: Icons.check_rounded,
            color: context.palette.fern,
            filled: true,
            tooltip: 'Save name',
            onTap: _saveName,
          ),
        ],
      ),
    );
  }

  Widget _anonymousSection() {
    final p = context.palette;

    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Back up your plants',
            style: AppTheme.plantNameStyle(context, size: 19),
          ),
          const SizedBox(height: 6),
          Text(
            'Add an email and password so you can recover your Spaces and '
            'plants on a new device, or after reinstalling.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: p.inkSoft),
          ),
          Gap.lg,
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _upgrade(),
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorLine(message: _error!),
          ],
          Gap.md,
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
          Gap.lg,
          Row(
            children: [
              Expanded(child: Divider(color: p.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: TextStyle(fontSize: 12, color: p.inkFaint),
                ),
              ),
              Expanded(child: Divider(color: p.line)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final provider in const ['Apple', 'Google', 'Facebook'])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: provider == 'Facebook' ? 0 : 8,
                    ),
                    child: OutlinedButton(
                      onPressed: () => _showComingSoon(provider),
                      child: Text(provider),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountManagementSection() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetGroup(
          header: 'Account',
          dividerIndent: 56,
          margin: EdgeInsets.zero,
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
        Gap.md,
        InsetGroup(
          margin: EdgeInsets.zero,
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
        if (_error != null) ...[
          Gap.md,
          _ErrorLine(message: _error!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = AuthService.instance.isAnonymous;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Edit Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Gap.screen,
          16,
          Gap.screen,
          32,
        ),
        children: [
          _avatarSection(),
          Gap.md,
          _nameSection(),
          Gap.lg,
          if (isAnonymous) _anonymousSection() else _accountManagementSection(),
        ],
      ),
    );
  }
}

/// An inline form error, on a soft error-tinted panel rather than as bare red
/// text - so it reads as part of the form instead of a stray sentence.
class _ErrorLine extends StatelessWidget {
  final String message;

  const _ErrorLine({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: p.coralSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The change-password form.
///
/// A real widget rather than an inline `StatefulBuilder` inside `showDialog`,
/// so its two [TextEditingController]s are disposed when the dialog closes -
/// the previous inline version leaked one pair per invocation.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.length < 6) {
      setState(() => _error = 'Pick a password at least 6 characters long.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthService.instance.changePassword(
        _currentController.text,
        _newController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Password change failed: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = authErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: p.cardRaised,
          borderRadius: AppRadius.xlAll,
          boxShadow: p.shadowHi,
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change password',
              textAlign: TextAlign.center,
              style: AppTheme.plantNameStyle(context, size: 20),
            ),
            Gap.md,
            TextField(
              controller: _currentController,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Current password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorLine(message: _error!),
            ],
            Gap.lg,
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child:
                  _submitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Save'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: p.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
