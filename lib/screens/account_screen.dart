import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!AuthService.instance.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: scheme.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text(
                  'Account features aren\'t available on this platform',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAnonymous = AuthService.instance.isAnonymous;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!isAnonymous) ...[
            Icon(Icons.account_circle, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              AuthService.instance.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Gardens and plants are tied to this account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ] else ...[
            Icon(Icons.cloud_queue, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(
              'Your data is backed up, but only recoverable if you sign in',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save your account with an email and password so you can recover '
              'your Gardens and plants on a new device or after reinstalling.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
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
            ElevatedButton(
              onPressed: _isSubmitting ? null : _upgrade,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text('Save my account'),
            ),
          ],
        ],
      ),
    );
  }
}
