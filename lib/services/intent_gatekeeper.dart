/// Intent Gatekeeper Service
/// Layer 1 of the validation pipeline
/// 
/// Filters out trivial choices that don't need reflection.
/// A serious product is defined by what it refuses to do.
/// 
/// RULE: Accept only genuine life decisions with emotional uncertainty.
/// No loops. No autonomy. No advice. Just filtering.

/// Result from the Intent Gatekeeper
class IntentGatekeeperResult {
  /// Whether the input qualifies as a valid Parallel decision
  final bool isValidDecision;
  
  /// Gentle, non-shaming message explaining why input was rejected
  final String? rejectionMessage;
  
  /// Confidence score (0.0 - 1.0) for valid decisions
  final double confidence;

  const IntentGatekeeperResult({
    required this.isValidDecision,
    this.rejectionMessage,
    this.confidence = 1.0,
  });
  
  /// Quick constructor for valid decisions
  const IntentGatekeeperResult.valid({this.confidence = 1.0})
      : isValidDecision = true,
        rejectionMessage = null;
  
  /// Quick constructor for rejected input
  const IntentGatekeeperResult.rejected(this.rejectionMessage)
      : isValidDecision = false,
        confidence = 0.0;
}

/// Intent Gatekeeper - Rule-based decision filter
/// 
/// ACCEPTS only if ALL are true:
/// - First-person language (I, my, me)
/// - Uncertainty or hesitation
/// - Emotional or life impact
/// 
/// REJECTS immediately:
/// - How-to questions
/// - Comparisons without stakes
/// - Trivia / curiosity
/// - Jokes / hypotheticals without personal impact
class IntentGatekeeper {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FIRST PERSON DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// English first-person patterns
  static final RegExp _firstPersonEnglish = RegExp(
    r"\b(i|my|me|i'm|i am|myself|i've|i have|i'd|i would|i'll|i will)\b",
    caseSensitive: false,
  );
  
  /// Arabic first-person patterns
  static final RegExp _firstPersonArabic = RegExp(
    r'(أنا|انا|عندي|لي|حياتي|نفسي|روحي|انتي|راني|ني)',
  );
  
  /// French first-person patterns
  static final RegExp _firstPersonFrench = RegExp(
    r"\b(je|j'|mon|ma|mes|moi|moi-même)\b",
    caseSensitive: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // UNCERTAINTY DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// English uncertainty indicators
  static final RegExp _uncertaintyEnglish = RegExp(
    r"\b(not sure|unsure|wonder|wondering|thinking|hesitat|scared|afraid|don't know|dont know|uncertain|confused|torn|dilemma|stuck|lost|overwhelmed|anxious|worried|debating|considering|questioning)\b",
    caseSensitive: false,
  );
  
  /// English question patterns that imply uncertainty
  static final RegExp _questionUncertainty = RegExp(
    r"\b(should i|would i|could i|can i|do i|am i|will i|is it worth|is it time|is it right)\b",
    caseSensitive: false,
  );
  
  /// Arabic uncertainty indicators
  static final RegExp _uncertaintyArabic = RegExp(
    r'(مش عارف|ما نعرف|محتار|حيران|خايف|قلق|مش متأكد|ما اعرف|مو متأكد|محيرني|حاير|ماني عارف)',
  );
  
  /// French uncertainty indicators
  static final RegExp _uncertaintyFrench = RegExp(
    r"\b(pas sûr|hésit|peur|inquiet|perdu|confus|doute|incertain)\b",
    caseSensitive: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFE VERB DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// English life-impact verbs
  static final RegExp _lifeVerbsEnglish = RegExp(
    r"\b(quit|quitting|stay|staying|move|moving|leave|leaving|start|starting|change|changing|choose|choosing|continue|continuing|end|ending|accept|accepting|reject|rejecting|marry|marrying|divorce|divorcing|forgive|forgiving|trust|trusting|tell|telling|confess|confessing|break up|breaking up|get back|getting back|give up|giving up|let go|letting go|walk away|walking away|take the job|turn down|speak up|stay silent|reach out|cut off|commit|committing|pursue|pursuing|abandon|abandoning|confront|confronting)\b",
    caseSensitive: false,
  );
  
  /// Arabic life-impact verbs
  static final RegExp _lifeVerbsArabic = RegExp(
    r'(نمشي|نروح|نخلي|نبقى|نبدأ|نغير|نختار|نكمل|نوقف|اترك|امشي|اقعد|ابدأ|اغير|اختار|اكمل|اوقف|نسيب|اسيب|نفارق|نزوج|نطلق|نسامح|نثق|نقول|نعترف)',
  );
  
  /// French life-impact verbs
  static final RegExp _lifeVerbsFrench = RegExp(
    r"\b(quitter|rester|partir|déménager|commencer|changer|choisir|continuer|finir|terminer|accepter|refuser|divorcer|pardonner|avouer)\b",
    caseSensitive: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // REJECTION PATTERNS (Fast fail)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// How-to questions (immediate reject)
  static final RegExp _howToPattern = RegExp(
    r"^(how to|how do i|how can i|how should i|what is the best way to|what's the best way to)\b",
    caseSensitive: false,
  );
  
  /// Comparison without stakes (immediate reject)
  static final RegExp _trivialComparison = RegExp(
    r"^(which is better|what's better|should i get|should i buy|should i eat|should i have|should i order|should i watch|should i play|should i read)\b",
    caseSensitive: false,
  );
  
  /// Trivia patterns
  static final RegExp _triviaPattern = RegExp(
    r"^(what is|what are|who is|who are|when is|when was|where is|where are|why is|why are|what's|who's|when's)\b",
    caseSensitive: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GENTLE REJECTION MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> _rejectionMessages = [
    "Parallel works best with decisions that feel personal or uncertain.\nThis one might not need reflection.",
    "This feels more like a choice than a crossroads.",
    "Parallel is for decisions you're genuinely unsure about.",
    "This might not need both futures.\nParallel shines with weightier choices.",
  ];
  
  /// Get a gentle rejection message
  static String _getGentleRejection() {
    // Rotate through messages based on time for variety
    final index = DateTime.now().second % _rejectionMessages.length;
    return _rejectionMessages[index];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CHECK FUNCTION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Check if input qualifies as a valid Parallel decision
  /// 
  /// Returns [IntentGatekeeperResult] with validation status and optional message.
  static IntentGatekeeperResult check(String text) {
    final trimmed = text.trim();
    
    // Empty input - let other validators handle this
    if (trimmed.isEmpty) {
      return const IntentGatekeeperResult.valid();
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // FAST REJECT: Trivial patterns
    // ─────────────────────────────────────────────────────────────────────────
    
    if (_howToPattern.hasMatch(trimmed)) {
      return IntentGatekeeperResult.rejected(
        "Parallel explores decisions, not instructions.\nThis feels more like a how-to question.",
      );
    }
    
    if (_trivialComparison.hasMatch(trimmed)) {
      return IntentGatekeeperResult.rejected(
        "This feels more like a choice than a crossroads.\nParallel works best when you're genuinely unsure.",
      );
    }
    
    if (_triviaPattern.hasMatch(trimmed)) {
      return IntentGatekeeperResult.rejected(
        "Parallel is for decisions you're weighing,\nnot questions you're answering.",
      );
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // DETECT: First-person language
    // ─────────────────────────────────────────────────────────────────────────
    
    final hasFirstPerson = _firstPersonEnglish.hasMatch(trimmed) ||
        _firstPersonArabic.hasMatch(trimmed) ||
        _firstPersonFrench.hasMatch(trimmed);
    
    // ─────────────────────────────────────────────────────────────────────────
    // DETECT: Uncertainty or hesitation
    // ─────────────────────────────────────────────────────────────────────────
    
    final hasUncertainty = _uncertaintyEnglish.hasMatch(trimmed) ||
        _questionUncertainty.hasMatch(trimmed) ||
        _uncertaintyArabic.hasMatch(trimmed) ||
        _uncertaintyFrench.hasMatch(trimmed);
    
    // ─────────────────────────────────────────────────────────────────────────
    // DETECT: Life-impact verbs
    // ─────────────────────────────────────────────────────────────────────────
    
    final hasLifeVerb = _lifeVerbsEnglish.hasMatch(trimmed) ||
        _lifeVerbsArabic.hasMatch(trimmed) ||
        _lifeVerbsFrench.hasMatch(trimmed);
    
    // ─────────────────────────────────────────────────────────────────────────
    // DECISION LOGIC
    // ─────────────────────────────────────────────────────────────────────────
    
    // Perfect match: All three signals present
    if (hasFirstPerson && hasUncertainty && hasLifeVerb) {
      return const IntentGatekeeperResult.valid(confidence: 1.0);
    }
    
    // Strong match: First person + life verb (implied uncertainty)
    if (hasFirstPerson && hasLifeVerb) {
      return const IntentGatekeeperResult.valid(confidence: 0.85);
    }
    
    // Good match: First person + uncertainty (we can infer the decision)
    if (hasFirstPerson && hasUncertainty) {
      return const IntentGatekeeperResult.valid(confidence: 0.75);
    }
    
    // Acceptable: Just first person with enough length (user is sharing something personal)
    if (hasFirstPerson && trimmed.length >= 30) {
      return const IntentGatekeeperResult.valid(confidence: 0.6);
    }
    
    // Has a life verb but no first person - might still be valid
    // "Should I quit my job" doesn't have "I" as \b word but is clearly first person
    if (hasLifeVerb && hasUncertainty) {
      return const IntentGatekeeperResult.valid(confidence: 0.7);
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // REJECT: Doesn't look like a personal decision
    // ─────────────────────────────────────────────────────────────────────────
    
    return IntentGatekeeperResult.rejected(_getGentleRejection());
  }
  
  /// Quick check for use in simple boolean contexts
  static bool isValidDecision(String text) {
    return check(text).isValidDecision;
  }
}
