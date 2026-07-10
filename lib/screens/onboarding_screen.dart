import 'package:flutter/material.dart';

import '../services/onboarding_preferences.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../utils/haptics.dart';
import 'main_shell.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String message;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.message,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.camera_alt_outlined,
    title: 'Identify any plant',
    message:
        "Snap a photo and we'll help identify your plant's species, "
        'plus give you real care info.',
  ),
  _OnboardingPage(
    icon: Icons.water_drop_outlined,
    title: 'Never forget to water or fertilize',
    message:
        'Track watering and fertilizing schedules for every plant, '
        "with reminders right when they're due.",
  ),
  _OnboardingPage(
    icon: Icons.eco_outlined,
    title: 'Discover, propagate, and grow your collection',
    message:
        'Browse thousands of species, track cuttings and divisions, '
        'and watch your plants thrive with local weather insights.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPreferences.instance.setCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacement(context, appRoute(const MainShell()));
  }

  void _next() {
    Haptics.selection();
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    final scheme = Theme.of(context).colorScheme;
    final fern = AppTheme.fernColor(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: fern.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 52, color: fern),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            style: AppTheme.plantNameStyle(context, size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fern = AppTheme.fernColor(context);
    final scheme = Theme.of(context).colorScheme;
    final isLastPage = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: _pages.map(_buildPage).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _page ? fern : scheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: fern,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
