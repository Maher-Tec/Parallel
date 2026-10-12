import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/parallel_path_animation.dart';
import '../widgets/dream_button.dart';
import 'input_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';
import '../app_config.dart';

/// S0 — Launch / Intent Screen
/// Sets emotional contract with the user
/// Feels like opening a book
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AmbientBackground(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - progress)),
              child: child,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(190),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.accent.withAlpha(70)),
                    ),
                    child: Text(
                      'A LITTLE SPACE FOR WHAT COULD BE',
                      style: AppTheme.bodySmall(context).copyWith(
                        color: AppTheme.rose,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Title with subtle glow
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppTheme.textPrimary,
                        AppTheme.rose,
                        AppTheme.accent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      AppConfig.name.toUpperCase(),
                      style: AppTheme.titleLarge(context).copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const ParallelPathAnimation(
                    width: 140,
                    height: 100,
                    showLabels: false,
                  ),
                  const SizedBox(height: 20),
                  // Concept text
                  Text(
                    'Write your dream. Say what you’ll do. See where it can lead.',
                    style: AppTheme.bodyMedium(context).copyWith(
                      fontSize: 18,
                      height: 1.6,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start with one small step you can take.',
                    style: AppTheme.bodyMedium(
                      context,
                    ).copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  DreamButton(
                    label: 'Begin',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InputScreen()),
                      );
                    },
                  ),
                  const Spacer(),
                  // Bottom navigation with divider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'My Dreams',
                          style: AppTheme.bodySmall(context),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: AppTheme.divider,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'About',
                          style: AppTheme.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
