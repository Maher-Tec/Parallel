import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/decision_entry.dart';
import '../storage/local_store.dart';
import '../services/memory_service.dart';
import 'launch_screen.dart';

/// S3 — Results Screen (Core Experience)
/// Tabbed view with two parallel stories
/// Cinematic reading experience with fade-in animation
/// RTL support for Arabic text
class ResultScreen extends StatefulWidget {
  final String decision;
  final String tone;
  final String resultIfAct;
  final String resultIfNot;
  final DecisionEntry? existingEntry;

  const ResultScreen({
    super.key,
    required this.decision,
    required this.tone,
    required this.resultIfAct,
    required this.resultIfNot,
    this.existingEntry,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalStore _store = LocalStore();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isSaved = widget.existingEntry != null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_isSaved) return;

    // Extract tags for future continuity detection
    final tags = MemoryService.extractTags(widget.decision);

    final entry = DecisionEntry.create(
      decision: widget.decision,
      tone: widget.tone,
      resultIfAct: widget.resultIfAct,
      resultIfNot: widget.resultIfNot,
      tags: tags,
    );

    await _store.saveEntry(entry);

    if (mounted) {
      setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved to history',
            style: AppTheme.bodySmall(context).copyWith(
              color: AppTheme.background,
            ),
          ),
          backgroundColor: AppTheme.textPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyCurrentContent() {
    // Copy the current tab's content
    final content = _tabController.index == 0
        ? 'IF YOU ACT:\n\n${widget.resultIfAct}'
        : "IF YOU DON'T ACT:\n\n${widget.resultIfNot}";
    
    Clipboard.setData(ClipboardData(text: content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: AppTheme.bodySmall(context).copyWith(
            color: AppTheme.background,
          ),
        ),
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _newDecision() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LaunchScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: AppTheme.textSecondary),
            onPressed: _copyCurrentContent,
            tooltip: 'Copy text',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.textPrimary,
            indicatorWeight: 1,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: AppTheme.bodyMedium(context),
            tabs: const [
              Tab(text: 'If You Act'),
              Tab(text: "If You Don't"),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Story content with cinematic fade-in
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _StoryView(
                  title: 'IF YOU ACT',
                  content: widget.resultIfAct,
                ),
                _StoryView(
                  title: "IF YOU DON'T ACT",
                  content: widget.resultIfNot,
                ),
              ],
            ),
          ),
          // Bottom actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.divider,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSaved ? null : _saveEntry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                            color: _isSaved
                                ? AppTheme.withAlpha(AppTheme.textSecondary, 0.2)
                                : AppTheme.withAlpha(AppTheme.textPrimary, 0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        _isSaved ? 'Saved' : 'Save',
                        style: AppTheme.button(context).copyWith(
                          color: _isSaved
                              ? AppTheme.withAlpha(AppTheme.textSecondary, 0.5)
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: _newDecision,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            AppTheme.withAlpha(AppTheme.textPrimary, 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'New Decision',
                        style: AppTheme.button(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Story view widget with cinematic paragraph-by-paragraph fade-in
/// Auto-detects Arabic text and applies RTL direction
class _StoryView extends StatefulWidget {
  final String title;
  final String content;

  const _StoryView({
    required this.title,
    required this.content,
  });

  @override
  State<_StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<_StoryView> with TickerProviderStateMixin {
  late List<String> _paragraphs;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late bool _isRTL;

  /// Detect if text contains Arabic characters
  static bool _containsArabic(String text) {
    // Arabic Unicode range: \u0600-\u06FF (Arabic)
    // Also includes Arabic Extended: \u0750-\u077F, \u08A0-\u08FF
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _isRTL = _containsArabic(widget.content);
    _setupAnimations();
  }

  void _setupAnimations() {
    // Split content into paragraphs
    _paragraphs = widget.content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // Create animation controllers for each paragraph
    _controllers = List.generate(
      _paragraphs.length + 1, // +1 for title
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    // Create fade and slide animations
    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    // Start animations with staggered delay
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _controllers[i].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment:
                  _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Animated title
                if (_fadeAnimations.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: SlideTransition(
                      position: _slideAnimations[0],
                      child: Text(
                        widget.title,
                        style: AppTheme.titleSmall(context).copyWith(
                          letterSpacing: 2,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                // Animated paragraphs
                ...List.generate(_paragraphs.length, (index) {
                  final animIndex = index + 1;
                  if (animIndex >= _fadeAnimations.length) {
                    return Text(
                      _paragraphs[index],
                      style: AppTheme.bodyLarge(context),
                      textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimations[animIndex],
                      child: SlideTransition(
                        position: _slideAnimations[animIndex],
                        child: Text(
                          _paragraphs[index],
                          style: AppTheme.bodyLarge(context),
                          textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
