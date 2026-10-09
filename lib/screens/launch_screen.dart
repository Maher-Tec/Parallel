import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/parallel_path_animation.dart';
import 'input_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Title with subtle glow
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.textPrimary,
                      AppTheme.accent.withAlpha(200),
                      AppTheme.textPrimary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'PARALLEL',
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
                  'Write a decision you are facing.',
                  style: AppTheme.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We will explore two futures:',
                  style: AppTheme.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'one where you act,',
                  style: AppTheme.bodyMedium(context).copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "one where you don't.",
                  style: AppTheme.bodyMedium(context).copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                // Begin button with enhanced style
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.surface,
                        AppTheme.withAlpha(AppTheme.accent, 0.1),
                      ],
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InputScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.withAlpha(AppTheme.textPrimary, 0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Begin',
                          style: AppTheme.button(context),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: AppTheme.textPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
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
                        'History',
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
    );
  }
}
