import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/fallback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/parallel_path_animation.dart';
import 'result_screen.dart';

class PauseScreen extends StatefulWidget {
  final String dreamText;
  final List<String> actions;
  final bool isRtl;
  const PauseScreen({
    super.key,
    required this.dreamText,
    required this.actions,
    this.isRtl = false,
  });
  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true, period: const Duration(seconds: 3));
  String? _error;
  int _phase = 0;
  final _phases = const [
    'Following the steps you chose…',
    'Making room for a real obstacle…',
    'Keeping the picture grounded…',
  ];
  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _fade.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!mounted) return;
    setState(() => _error = null);
    final startedAt = DateTime.now();
    unawaited(_cyclePhases());
    Map<String, String> result;
    try {
      result = await AIService().generateFutures(
        dream: widget.dreamText,
        actions: widget.actions,
      );
    } catch (e) {
      debugPrint('Gemini failed, using OpenRouter: $e');
      try {
        result = await FallbackService().generateFutures(
          dream: widget.dreamText,
          actions: widget.actions,
        );
      } catch (fallbackError) {
        debugPrint('OpenRouter failed: $fallbackError');
        if (mounted) {
          setState(
            () => _error =
                'Both scenario services failed. Check your internet connection and API keys in .env, then try again.',
          );
        }
        return;
      }
    }
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(seconds: 3) - elapsed);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          dreamText: widget.dreamText,
          actions: widget.actions,
          scenarioDo: result['ifAct'] ?? '',
          scenarioNot: result['ifNot'] ?? '',
        ),
      ),
    );
  }

  Future<void> _cyclePhases() async {
    while (mounted && _error == null) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && _error == null) {
        setState(() => _phase = (_phase + 1) % _phases.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: AmbientBackground(
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _error == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ParallelPathAnimation(
                          width: 250,
                          height: 190,
                          showLabels: true,
                          leftLabel: widget.isRtl
                              ? 'إذا قمت بالعمل'
                              : 'IF YOU DO THE WORK',
                          rightLabel: widget.isRtl
                              ? 'إذا لم يتغير شيء'
                              : 'IF NOTHING CHANGES',
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'A moment to imagine.',
                          style: AppTheme.titleSmall(context),
                        ),
                        const SizedBox(height: 14),
                        FadeTransition(
                          opacity: _text,
                          child: Text(
                            _phases[_phase],
                            style: AppTheme.bodyMedium(context),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium(context),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _generate,
                          child: const Text('Try again'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
