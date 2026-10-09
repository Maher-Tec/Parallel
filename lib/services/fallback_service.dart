import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenRouter Fallback Service
/// Activated when primary AI fails (quota, timeout, etc.)
class FallbackService {
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "nvidia/nemotron-3-super-120b-a12b:free";

  static const int _maxTokens = 900;
  static const double _temperature = 0.7;
  static const Duration _timeout = Duration(seconds: 45);

  /// Get API key from environment
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// System prompt
  static const String _systemPrompt = """
You are a reflective fiction writer exploring two parallel futures based on a human dilemma.

CRITICAL PRINCIPLES:
- STRICT SUBJECT FIDELITY: Stay laser-focused on the exact subject, relationship, and situation described. If the decision is about someone else's idea or relationship (e.g. your friend's business idea), BOTH stories must center on that friend, that conversation, and the consequences for that relationship. NEVER invent unrelated contexts (do NOT turn it into your own career, job hunt, coding, or startup).
- NO PROPER NAMES: NEVER invent fictional character names (do NOT name people "Sarah", "David", "Alex", "Mark", "Emma", etc.). Refer to people naturally by their relation: "your friend", "she", "he", "your partner", "your colleague", "the client".
- NO CLICHÉ TEMPLATES: Do NOT default to office cubicles, corporate commutes, tech startups, Stripe dashboards, or coding bugs unless the user explicitly mentioned them.
- REALISTIC CONSEQUENCES:
  * In Path 1 (ACT): Show the direct reality of taking the action — the conversation itself, the immediate reaction, and the ripple effect on your relationship or life months later.
  * In Path 2 (DON'T ACT): Show the quiet reality of restraint — the conversation avoided, what happens to the situation over time, and the internal weight of having stayed silent.
- Calm, intimate, emotionally grounded tone.
- No advice. No judgment. No moralizing.
""";

  /// Tone modifiers
  static String _getToneModifier(String tone) {
    if (tone == 'light') {
      return """
Writing tone: LIGHT
Warm and gentle irony. Emotions mixed but not crushing.
""";
    }
    return """
Writing tone:
Serious, calm, introspective, emotionally grounded.
""";
  }

  /// Build user prompt
  static String _buildUserPrompt(String decision, String tone) {
    final toneModifier = _getToneModifier(tone);

    return """
**CRITICAL LANGUAGE RULE:**
Write in the EXACT SAME LANGUAGE/DIALECT as the decision below (Tunisian Arabic, French, or English).

$toneModifier

Decision:
$decision

Write two short reflective stories in SECOND PERSON ("you") in the SAME LANGUAGE as the decision above:
1) IF YOU ACT
2) IF YOU DO NOT ACT

Rules:
- 250–350 words per story
- Second person ("you")
- STRICT SUBJECT FIDELITY: Keep BOTH stories focused strictly on the specific dilemma and people mentioned in the decision.
- NEVER USE ANY CHARACTER NAMES. Refer to people only as "your friend", "she", "he", "your colleague", etc.
- Ground each story in concrete, sensory moments: pauses in conversation, tone of voice, quiet changes in daily rhythm, the physical space between people.
- No advice, no lecturing, no moral conclusions.

Format EXACTLY as:
===STORY_ACT===
[story in user's language]

===STORY_NOT===
[story in user's language]
""";
  }

  /// Generate parallel futures
  Future<Map<String, String>> generateFutures({
    required String decision,
    required String tone,
    String? memoryContext,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    String systemPrompt = _systemPrompt;
    if (memoryContext != null && memoryContext.isNotEmpty) {
      systemPrompt = '$_systemPrompt\n\n$memoryContext';
    }

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://parallel.app',
            'X-Title': 'Parallel',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': _buildUserPrompt(decision, tone)},
            ],
            'max_tokens': _maxTokens,
            'temperature': _temperature,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No choices returned by OpenRouter');
    }

    final rawContent = choices[0]['message']?['content'];
    final content = (rawContent != null) ? rawContent.toString() : '';

    if (content.trim().isEmpty) {
      throw Exception('Empty content from OpenRouter fallback');
    }

    return _parseResponse(content);
  }

  /// Parse the AI response into two stories
  static Map<String, String> _parseResponse(String content) {
    const actMarker = '===STORY_ACT===';
    const notMarker = '===STORY_NOT===';

    String ifAct = '';
    String ifNot = '';

    if (content.contains(actMarker) && content.contains(notMarker)) {
      final actIndex = content.indexOf(actMarker);
      final notIndex = content.indexOf(notMarker);

      if (actIndex < notIndex) {
        ifAct = content.substring(actIndex + actMarker.length, notIndex).trim();
        ifNot = content.substring(notIndex + notMarker.length).trim();
      }
    }

    // Fallback parsing if markers not found
    if (ifAct.isEmpty || ifNot.isEmpty) {
      final patterns = ['IF YOU DO NOT ACT', 'IF YOU DON\'T ACT', '2)', '2.'];

      for (final pattern in patterns) {
        if (content.contains(pattern)) {
          final idx = content.indexOf(pattern);
          ifAct = content.substring(0, idx).trim();
          ifNot = content.substring(idx).trim();

          final actPatterns = ['IF YOU ACT', '1)', '1.'];
          for (final p in actPatterns) {
            final pIdx = ifAct.indexOf(p);
            if (pIdx != -1) {
              ifAct = ifAct.substring(pIdx + p.length).trim();
              break;
            }
          }
          ifNot = ifNot.substring(pattern.length).trim();
          break;
        }
      }
    }

    if (ifAct.isEmpty && ifNot.isEmpty) {
      final mid = content.length ~/ 2;
      ifAct = content.substring(0, mid).trim();
      ifNot = content.substring(mid).trim();
    }

    return {'ifAct': ifAct, 'ifNot': ifNot};
  }
}
