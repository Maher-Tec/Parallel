import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// S5 — About Screen
/// Minimal philosophy and privacy statement
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About',
          style: AppTheme.titleSmall(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parallel explores decisions through quiet, fictional futures.',
                    style: AppTheme.bodyLarge(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'It does not give advice.',
                    style: AppTheme.bodyMedium(context).copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It does not judge.',
                    style: AppTheme.bodyMedium(context).copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.divider,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy',
                          style: AppTheme.titleSmall(context).copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your decisions are processed temporarily to generate text. No data is stored remotely.',
                          style: AppTheme.bodySmall(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  Center(
                    child: Text(
                      'v1.0',
                      style: AppTheme.bodySmall(context).copyWith(
                        color: AppTheme.withAlpha(AppTheme.textSecondary, 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
