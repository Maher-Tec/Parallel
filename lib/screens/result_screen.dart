import 'package:flutter/material.dart';
import '../models/dream.dart';
import '../storage/local_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/dream_horizon.dart';
import 'reminder_setup_screen.dart';

class ResultScreen extends StatefulWidget {
  final String dreamText;
  final List<String> actions;
  final String scenarioDo;
  final String scenarioNot;
  final Dream? existingDream;
  const ResultScreen({
    super.key,
    required this.dreamText,
    required this.actions,
    required this.scenarioDo,
    required this.scenarioNot,
    this.existingDream,
  });
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _store = LocalStore();
  Dream? _savedDream;
  bool _saving = false;
  bool get _saved => _savedDream != null;

  @override
  void initState() {
    super.initState();
    _savedDream = widget.existingDream;
    _findExisting();
  }

  Future<void> _findExisting() async {
    final dreams = await _store.getDreams();
    if (!mounted || _savedDream != null) return;
    for (final dream in dreams) {
      if (dream.text == widget.dreamText &&
          dream.scenarioDo == widget.scenarioDo &&
          dream.scenarioNot == widget.scenarioNot) {
        setState(() => _savedDream = dream);
        return;
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final dream =
        _savedDream ??
        Dream(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: widget.dreamText
              .trim()
              .split(RegExp(r'\s+'))
              .take(7)
              .join(' '),
          text: widget.dreamText,
          actions: widget.actions.map((a) => DreamAction(text: a)).toList(),
          scenarioDo: widget.scenarioDo,
          scenarioNot: widget.scenarioNot,
          createdAt: DateTime.now(),
          tags: [],
        );
    await _store.saveDream(dream);
    if (mounted) {
      setState(() => _savedDream = dream);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReminderSetupScreen(dream: dream)),
      );
    }
  }

  bool _isRtl(String text) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);

  Widget _storyPage(String story, {required bool showActions}) {
    final paragraphs = story
        .trim()
        .split(RegExp(r'\n\s*\n+'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList();
    final isRtl = _isRtl(story);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .97, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: ((value - .97) / .03).clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: value, child: child),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: showActions
                      ? AppTheme.accent
                      : const Color(0xFFAAB5CC),
                ),
                const SizedBox(width: 8),
                Text(
                  showActions ? 'A POSSIBLE PATH' : 'A QUIETER POSSIBILITY',
                  style: AppTheme.bodySmall(context).copyWith(
                    color: showActions
                        ? AppTheme.accent
                        : const Color(0xFFAAB5CC),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: showActions
                      ? AppTheme.accent
                      : const Color(0xFFAAB5CC),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: _isRtl(widget.dreamText)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Text(
                widget.dreamText.trim(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titleMedium(
                  context,
                ).copyWith(color: AppTheme.textPrimary, height: 1.25),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: showActions
                      ? [
                          AppTheme.surface.withAlpha(225),
                          AppTheme.surface.withAlpha(195),
                          const Color(0xFF28232B).withAlpha(205),
                        ]
                      : [
                          const Color(0xFF202536).withAlpha(230),
                          const Color(0xFF171C29).withAlpha(205),
                          const Color(0xFF1D202C).withAlpha(215),
                        ],
                ),
                border: Border.all(
                  color:
                      (showActions ? AppTheme.accent : const Color(0xFF9BAAC8))
                          .withAlpha(48),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withAlpha(14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (showActions
                                        ? AppTheme.accent
                                        : const Color(0xFF9BAAC8))
                                    .withAlpha(25),
                          ),
                          child: Icon(
                            showActions
                                ? Icons.light_mode_outlined
                                : Icons.nightlight_outlined,
                            size: 16,
                            color: showActions
                                ? AppTheme.accent
                                : const Color(0xFFB6C2D9),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          showActions
                              ? 'A glimpse of the path ahead'
                              : 'If the days stay much the same',
                          style: AppTheme.bodySmall(context).copyWith(
                            color: showActions
                                ? AppTheme.rose
                                : const Color(0xFFB6C2D9),
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Directionality(
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < paragraphs.length; i++) ...[
                            if (i > 0) const SizedBox(height: 18),
                            Text(
                              paragraphs[i].trim(),
                              textAlign: isRtl
                                  ? TextAlign.right
                                  : TextAlign.left,
                              style: AppTheme.bodyLarge(context).copyWith(
                                fontSize: 19,
                                height: 1.9,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 26),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 1,
                    color: AppTheme.accent.withAlpha(130),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'THE STEPS YOU CHOSE',
                    style: AppTheme.bodySmall(context).copyWith(
                      color: AppTheme.accent,
                      fontSize: 11,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...widget.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(175),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: AppTheme.accent.withAlpha(32)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withAlpha(25),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Directionality(
                          textDirection: _isRtl(action)
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Text(
                            action,
                            style: AppTheme.bodySmall(context).copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AmbientBackground(
    child: Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: DreamHorizon(
              key: ValueKey(_tabs.index),
              fullBleed: true,
              alternate: _tabs.index == 1,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('Your dream'),
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'If you do the work'),
                Tab(text: 'If nothing changes'),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _storyPage(widget.scenarioDo, showActions: true),
                    _storyPage(widget.scenarioNot, showActions: false),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saved ? 'Continue to reminder' : 'Save as a Dream',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
