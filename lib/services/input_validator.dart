/// Input Validation Service
/// Detects gibberish, spam, and nonsensical input
/// Ensures only meaningful decisions are processed
class InputValidator {
  /// Minimum ratio of unique characters to total (prevents "aaaaaaa")
  static const double _minUniqueCharRatio = 0.25;

  /// Maximum ratio of repeated adjacent characters (prevents "aaabbbccc")
  static const double _maxRepeatRatio = 0.4;

  /// Common patterns that indicate gibberish
  static final List<RegExp> _gibberishPatterns = [
    RegExp(r'(.)\1{4,}'), // Same character 5+ times in a row
    RegExp(r'^[^aeiouAEIOUأإاآوىيةء\s]{10,}$'), // 10+ consonants only (no vowels)
    RegExp(r'^[\W\d\s]+$'), // Only special chars, numbers, spaces
    RegExp(r'[qwfpgjluyQWFPGJLUY]{6,}'), // Keyboard left-hand spam
    RegExp(r'[zxcvbnmZXCVBNM]{6,}'), // Keyboard bottom row spam
    RegExp(r'[asdfghjklASDFGHJKL]{7,}'), // Keyboard middle row spam
  ];

  /// Words that indicate a real question/decision (English)
  static final Set<String> _decisionIndicators = {
    'should', 'would', 'could', 'can', 'will', 'do', 'is', 'are', 'if',
    'whether', 'want', 'need', 'think', 'feel', 'maybe', 'perhaps',
    'or', 'and', 'but', 'because', 'what', 'how', 'why', 'when',
    'move', 'leave', 'stay', 'quit', 'start', 'stop', 'change', 'keep',
    'tell', 'say', 'ask', 'accept', 'reject', 'try', 'give', 'take',
  };

  /// Arabic decision indicators
  static final Set<String> _arabicIndicators = {
    'هل', 'لو', 'اذا', 'إذا', 'ممكن', 'لازم', 'يجب', 'أريد', 'عايز', 'نحب',
    'باش', 'بش', 'وإلا', 'ولا', 'كيف', 'كيفاش', 'علاش', 'ليش', 'متى', 'وين',
    'أو', 'او', 'لكن', 'بس', 'خلاص', 'يعني', 'قررت', 'حيرة', 'محتار',
  };

  /// French decision indicators
  static final Set<String> _frenchIndicators = {
    'est-ce', 'dois', 'devrais', 'pourrais', 'faut', 'veux', 'peux',
    'si', 'ou', 'peut-être', 'comment', 'pourquoi', 'quand', 'où',
    'partir', 'rester', 'quitter', 'commencer', 'arrêter', 'changer',
  };

  /// Validate input and return result
  static ValidationResult validate(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        reason: 'Please enter your decision.',
      );
    }

    // Check for excessive character repetition
    if (_hasExcessiveRepetition(trimmed)) {
      return ValidationResult(
        isValid: false,
        reason: 'Please enter a real decision or question.',
      );
    }

    // Check for gibberish patterns
    for (final pattern in _gibberishPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return ValidationResult(
          isValid: false,
          reason: 'This doesn\'t look like a decision. Try rephrasing.',
        );
      }
    }

    // Check for unique character ratio (too low = spam)
    if (!_hasEnoughUniqueChars(trimmed)) {
      return ValidationResult(
        isValid: false,
        reason: 'Please describe your decision with more variety.',
      );
    }

    // Check for at least one decision indicator word
    if (!_hasDecisionIndicators(trimmed)) {
      // Not an error, just a warning - AI can still try
      return ValidationResult(
        isValid: true,
        warning: 'Consider phrasing as a question or decision.',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Check if text has excessive repeated characters
  static bool _hasExcessiveRepetition(String text) {
    if (text.length < 5) return false;

    int repeatCount = 0;
    for (int i = 1; i < text.length; i++) {
      if (text[i] == text[i - 1]) {
        repeatCount++;
      }
    }

    return (repeatCount / text.length) > _maxRepeatRatio;
  }

  /// Check if text has enough unique characters
  static bool _hasEnoughUniqueChars(String text) {
    if (text.length < 10) return true;

    final chars = text.replaceAll(RegExp(r'\s'), '').toLowerCase();
    final uniqueChars = chars.split('').toSet();

    return (uniqueChars.length / chars.length) >= _minUniqueCharRatio;
  }

  /// Check if text contains decision indicator words
  static bool _hasDecisionIndicators(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[\s\W]+'));

    // Check English
    for (final word in words) {
      if (_decisionIndicators.contains(word)) return true;
    }

    // Check Arabic
    for (final indicator in _arabicIndicators) {
      if (text.contains(indicator)) return true;
    }

    // Check French
    for (final indicator in _frenchIndicators) {
      if (lower.contains(indicator)) return true;
    }

    // Also accept if it has a question mark
    if (text.contains('?') || text.contains('؟')) return true;

    return false;
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? reason;
  final String? warning;

  ValidationResult({
    required this.isValid,
    this.reason,
    this.warning,
  });
}
