import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/fallback_service.dart';
import '../services/memory_service.dart';
import '../storage/local_store.dart';
import '../widgets/ambient_background.dart';
import 'result_screen.dart';

/// S2 — Pause / Reflection Screen
/// Creates intentional pause + hides API latency
/// Features Lottie loading animation for a premium feel
/// Includes Decision Memory for narrative continuity
class PauseScreen extends StatefulWidget {
  final String decision;
  final String tone;

  const PauseScreen({
    super.key,
    required this.decision,
    required this.tone,
  });

  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _textAnimController;
  late Animation<double> _textAnimation;

  final AIService _aiService = AIService();
  final FallbackService _fallbackService = FallbackService();
  final LocalStore _localStore = LocalStore();

  String? _error;
  Map<String, String>? _results;

  // Decision Memory state
  String? _memoryContext;
  bool _showContinuityHint = false;

  DateTime? _startTime;
  static const Duration _minDisplayTime = Duration(seconds: 3);

  // Current phase text
  int _currentPhase = 0;
  final List<String> _phaseTexts = [
    'Imagining your first path...',
    'Now exploring the other...',
    'Weaving both futures...',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Text fade animation for phase changes
    _textAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeInOut),
    );
    _textAnimController.forward();

    _initializeAndGenerate();
    _startPhaseAnimation();
  }

  void _startPhaseAnimation() async {
    while (mounted && _error == null && _results == null) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && _error == null && _results == null) {
        _textAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentPhase = (_currentPhase + 1) % _phaseTexts.length;
            });
            _textAnimController.forward();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textAnimController.dispose();
    super.dispose();
  }

  /// Initialize memory check and generate futures
  Future<void> _initializeAndGenerate() async {
    // Check for decision continuity
    await _checkDecisionContinuity();

    // Generate futures with context if available
    await _generateFutures();
  }

  /// Check if this decision relates to past reflections
  Future<void> _checkDecisionContinuity() async {
    try {
      final history = await _localStore.getHistory();

      if (history.isNotEmpty) {
        final related = MemoryService.findRelatedDecision(
          widget.decision,
          history,
        );

        if (related != null) {
          _memoryContext = MemoryService.buildContextPrompt(related);

          // Check if we should show the hint (once per chain)
          final newTags = MemoryService.extractTags(widget.decision);
          final matchingTags = newTags
              .where((tag) =>
                  related.tags.contains(tag) ||
                  MemoryService.extractTags(related.decision).contains(tag))
              .toList();

          final shouldShow = await MemoryService.shouldShowContinuityHint(
            matchingTags,
            _localStore,
          );

          if (shouldShow && mounted) {
            setState(() {
              _showContinuityHint = true;
            });
            // Mark hint as shown for these tags
            await MemoryService.markHintShown(matchingTags, _localStore);
          }
        }
      }
    } catch (e) {
      // Silently fail - memory is optional enhancement
    }
  }

  Future<void> _generateFutures() async {
    try {
      // Try OpenAI first, with memory context if available
      _results = await _aiService.generateFutures(
        decision: widget.decision,
        tone: widget.tone,
        memoryContext: _memoryContext,
      );
    } catch (e) {
      // Fallback to OpenRouter
      try {
        _results = await _fallbackService.generateFutures(
          decision: widget.decision,
          tone: widget.tone,
          memoryContext: _memoryContext,
        );
      } catch (fallbackError) {
        if (mounted) {
          setState(() {
            _error = 'Unable to generate futures. Please try again.';
          });
        }
        return;
      }
    }

    if (!mounted) return;

    // Ensure minimum display time
    final elapsed = DateTime.now().difference(_startTime!);
    if (elapsed < _minDisplayTime) {
      await Future.delayed(_minDisplayTime - elapsed);
    }

    if (!mounted) return;

    // Navigate to results
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          decision: widget.decision,
          tone: widget.tone,
          resultIfAct: _results!['ifAct'] ?? '',
          resultIfNot: _results!['ifNot'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error != null) ...[
                    // Error state
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.withAlpha(AppTheme.accent, 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: AppTheme.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: AppTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go back',
                        style: AppTheme.button(context),
                      ),
                    ),
                  ] else ...[
                    // Loading state with Lottie
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Lottie.asset(
                        'assets/loading.json',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Primary text
                    Text(
                      'Pause for a moment.',
                      style: AppTheme.titleSmall(context).copyWith(
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Phase text with animation
                    FadeTransition(
                      opacity: _textAnimation,
                      child: Text(
                        _phaseTexts[_currentPhase],
                        style: AppTheme.bodyMedium(context).copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Subtle continuity hint (shown once per chain)
                    if (_showContinuityHint) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.withAlpha(AppTheme.textPrimary, 0.05),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: AppTheme.textSecondary.withAlpha(150),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'This feels connected to a past reflection.',
                              style: AppTheme.bodySmall(context).copyWith(
                                color: AppTheme.textSecondary.withAlpha(150),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
