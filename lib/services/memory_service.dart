import '../models/decision_entry.dart';
import '../storage/local_store.dart';

/// Memory Service for Decision Continuity
/// Detects connections between current and past reflections
/// Never exposes memory explicitly — only deepens narrative realism
class MemoryService {
  /// Stopwords to filter out (common, non-meaningful words)
  static const Set<String> _stopwords = {
    // English stopwords
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your',
    'yours', 'yourself', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers',
    'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs',
    'themselves', 'what', 'which', 'who', 'whom', 'this', 'that', 'these',
    'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have',
    'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the',
    'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at',
    'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through',
    'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down',
    'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then',
    'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'each',
    'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only',
    'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will',
    'just', 'don', 'should', 'now', 'would', 'could', 'might', 'must',
    // French stopwords
    'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'le', 'la',
    'les', 'un', 'une', 'des', 'de', 'du', 'et', 'ou', 'mais', 'donc', 'car',
    'que', 'qui', 'quoi', 'ce', 'cette', 'ces', 'mon', 'ma', 'mes', 'ton',
    'ta', 'tes', 'son', 'sa', 'ses', 'notre', 'votre', 'leur', 'leurs',
    'est', 'sont', 'suis', 'es', 'sommes', 'êtes', 'ai', 'avons',
    'avez', 'ont', 'pour', 'avec', 'sans', 'dans', 'sur', 'sous', 'par',
    // Arabic transliterated common words
    'ana', 'enta', 'enti', 'howa', 'hiya', 'e7na', 'entouma', 'houma',
  };

  /// Generic tags that don't indicate meaningful continuity
  static const Set<String> _genericTags = {
    'life', 'choice', 'future', 'change', 'think', 'feel', 'want', 'need',
    'good', 'bad', 'better', 'best', 'maybe', 'probably', 'really', 'thing',
    'things', 'something', 'anything', 'nothing', 'everything', 'time',
    'way', 'day', 'year', 'years', 'make', 'take', 'get', 'know', 'like',
    // French equivalents
    'vie', 'choix', 'avenir', 'changer', 'penser', 'sentir', 'vouloir',
    'besoin', 'bien', 'mal', 'mieux', 'peut-être', 'vraiment', 'chose',
    'choses', 'quelque', 'rien', 'tout', 'temps', 'jour', 'année',
  };

  /// Extract meaningful keywords from decision text
  static List<String> extractTags(String decision) {
    // Normalize: lowercase, remove punctuation
    final normalized = decision
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Split into words
    final words = normalized.split(' ');

    // Filter: remove stopwords, keep meaningful words (3+ chars)
    final tags = <String>{};
    for (final word in words) {
      if (word.length >= 3 && !_stopwords.contains(word)) {
        tags.add(word);
      }
    }

    return tags.toList();
  }

  /// Check if a tag is non-generic (meaningful for continuity)
  static bool _isNonGenericTag(String tag) {
    return !_genericTags.contains(tag);
  }

  /// Find a related past decision based on tag similarity
  /// Returns the most recent matching entry, or null if no meaningful match
  static DecisionEntry? findRelatedDecision(
    String newDecision,
    List<DecisionEntry> history,
  ) {
    if (history.isEmpty) return null;

    final newTags = extractTags(newDecision);
    if (newTags.isEmpty) return null;

    DecisionEntry? bestMatch;
    int bestScore = 0;

    for (final entry in history) {
      // Get tags from stored entry, or extract if missing (backward compat)
      final entryTags = entry.tags.isNotEmpty
          ? entry.tags
          : extractTags(entry.decision);

      // Find matching tags
      final matchingTags = newTags.where((tag) => entryTags.contains(tag)).toList();
      final matchCount = matchingTags.length;

      // Check for non-generic matches
      final hasNonGeneric = matchingTags.any(_isNonGenericTag);

      // Require: at least 2 matches AND at least one non-generic
      if (matchCount >= 2 && hasNonGeneric) {
        // Prefer higher scores, then more recent entries
        if (matchCount > bestScore ||
            (matchCount == bestScore && entry.date.isAfter(bestMatch?.date ?? DateTime(0)))) {
          bestScore = matchCount;
          bestMatch = entry;
        }
      }
    }

    return bestMatch;
  }

  /// Build subtle context prompt for AI (never explicit)
  static String? buildContextPrompt(DecisionEntry? related) {
    if (related == null) return null;

    return '''
Context:
There has been prior reflection around a similar uncertainty.
This is not new — it is part of a continuing inner process.
Use this continuity subtly.
Do not mention the past explicitly.
''';
  }

  /// Check if hint should be shown (once per chain)
  static Future<bool> shouldShowContinuityHint(
    List<String> matchingTags,
    LocalStore store,
  ) async {
    final prefs = await store.getPrefs();
    final lastHintTags = prefs.getStringList('lastHintShownForTags') ?? [];

    // Check if we've already shown hint for these tags
    final hasOverlap = matchingTags.any((tag) => lastHintTags.contains(tag));
    
    return !hasOverlap;
  }

  /// Mark that hint was shown for these tags
  static Future<void> markHintShown(
    List<String> matchingTags,
    LocalStore store,
  ) async {
    final prefs = await store.getPrefs();
    final lastHintTags = prefs.getStringList('lastHintShownForTags') ?? [];
    
    // Add new tags, keep last 20 to prevent memory bloat
    final updatedTags = {...lastHintTags, ...matchingTags}.toList();
    if (updatedTags.length > 20) {
      updatedTags.removeRange(0, updatedTags.length - 20);
    }
    
    await prefs.setStringList('lastHintShownForTags', updatedTags);
  }
}
