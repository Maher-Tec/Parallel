import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/input_validator.dart';
import '../widgets/ambient_background.dart';
import 'pause_screen.dart';

/// S1 — Decision Input + Tone Screen
/// Captures the decision and emotional tone
/// Features RTL detection, enhanced design, and improved layout
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _tone = 'reflective';

  static const int _minChars = 20;
  static const int _maxChars = 300;

  bool get _meetsMinLength => _controller.text.length >= _minChars;
  int get _charCount => _controller.text.length;

  // RTL detection
  bool _isRTL = false;

  // Validation state
  String? _validationError;

  /// Detect if text contains Arabic characters
  static bool _containsArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }

  // Animation for button glow
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {}));

    // Subtle glow animation for the button when valid
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _onTextChanged() {
    final newIsRTL = _containsArabic(_controller.text);
    if (newIsRTL != _isRTL) {
      setState(() => _isRTL = newIsRTL);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _simulate() {
    if (!_meetsMinLength) return;

    // Validate input for gibberish
    final result = InputValidator.validate(_controller.text);
    if (!result.isValid) {
      setState(() {
        _validationError = result.reason;
      });
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _validationError = null);
      });
      return;
    }

    // Clear any previous error
    setState(() => _validationError = null);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PauseScreen(
          decision: _controller.text,
          tone: _tone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to adjust layout
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AmbientBackground(
        showParticles: !isKeyboardOpen, // Disable particles when keyboard open for performance
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Header
                        Text(
                          'What is the decision?',
                          style: AppTheme.titleMedium(context),
                        ),
                        const SizedBox(height: 16),

                        // Text input area
                        Container(
                          height: isKeyboardOpen ? 120 : 180,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? AppTheme.withAlpha(AppTheme.textPrimary, 0.3)
                                  : AppTheme.divider,
                              width: 1,
                            ),
                          ),
                          child: Directionality(
                            textDirection:
                                _isRTL ? TextDirection.rtl : TextDirection.ltr,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLength: _maxChars,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              textAlign: _isRTL ? TextAlign.right : TextAlign.left,
                              style: AppTheme.bodyLarge(context),
                              decoration: InputDecoration(
                                hintText: _isRTL
                                    ? 'ماذا يقلقك؟ اكتب هنا...'
                                    : 'Should I move to another country even if it means starting over?',
                                hintStyle: AppTheme.bodyLarge(context).copyWith(
                                  color: AppTheme.withAlpha(
                                      AppTheme.textSecondary, 0.4),
                                ),
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: AppTheme.textPrimary,
                              autofocus: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Character counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _charCount > 0 && _charCount < _minChars
                                ? AppTheme.withAlpha(AppTheme.accent, 0.1)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress indicator
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  value: (_charCount / _minChars).clamp(0.0, 1.0),
                                  strokeWidth: 2,
                                  backgroundColor: AppTheme.divider,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _charCount >= _minChars
                                        ? Colors.green.shade400
                                        : AppTheme.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_charCount / $_maxChars',
                                style: AppTheme.bodySmall(context).copyWith(
                                  color: _charCount < _minChars
                                      ? AppTheme.accent
                                      : AppTheme.textSecondary,
                                  fontWeight: _charCount >= _minChars
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_charCount > 0 && _charCount < _minChars) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${_minChars - _charCount} more',
                                  style: AppTheme.bodySmall(context).copyWith(
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tone selector - compact when keyboard is open
                        Text(
                          'Tone',
                          style: AppTheme.bodySmall(context).copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ToneChip(
                                label: 'Reflective',
                                isSelected: _tone == 'reflective',
                                onTap: () => setState(() => _tone = 'reflective'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ToneChip(
                                label: 'Light',
                                isSelected: _tone == 'light',
                                onTap: () => setState(() => _tone = 'light'),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Validation error display
                        if (_validationError != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.withAlpha(AppTheme.accent, 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.withAlpha(AppTheme.accent, 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _validationError!,
                                    style: AppTheme.bodySmall(context).copyWith(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // CTA Button
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              decoration: _meetsMinLength
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.textPrimary.withAlpha(
                                              (_glowAnimation.value * 40).round()),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: TextButton(
                                onPressed: _meetsMinLength ? _simulate : null,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: _meetsMinLength
                                      ? AppTheme.textPrimary
                                      : AppTheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Simulate both paths',
                                      style: AppTheme.button(context).copyWith(
                                        color: _meetsMinLength
                                            ? AppTheme.background
                                            : AppTheme.withAlpha(
                                                AppTheme.textSecondary, 0.4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_meetsMinLength) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppTheme.background,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: isKeyboardOpen ? 16 : 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

/// Compact tone chip widget
class _ToneChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToneChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.withAlpha(AppTheme.textPrimary, 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.textPrimary : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.bodyMedium(context).copyWith(
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
