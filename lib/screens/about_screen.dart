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
        title: Text('About', style: AppTheme.titleSmall(context)),
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
                    'Ufuq helps turn a dream into small, practical steps.',
                    style: AppTheme.bodyLarge(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'It offers a grounded scenario, not a promise about what will happen.',
                    style: AppTheme.bodyMedium(
                      context,
                    ).copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your dream and actions are sent to Gemini to write your scenario. Saved history stays on this device.',
                    style: AppTheme.bodyMedium(
                      context,
                    ).copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.divider, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy',
                          style: AppTheme.titleSmall(
                            context,
                          ).copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dream text is sent to Gemini to generate your scenario. Your saved dreams and reminders stay on this device.',
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
