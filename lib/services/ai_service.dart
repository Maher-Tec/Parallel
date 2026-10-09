import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini API Service - Primary AI provider (Free Tier)
/// Generates parallel futures using reflective fiction writing
class AIService {
  static const String _model = "gemini-3.5-flash";
  static const Duration _timeout = Duration(seconds: 45);

  /// Get API key from environment
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get _apiUrl =>
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey";

  /// System prompt - reflective fiction writer persona
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
Writing tone: LIGHT (depth without gravity)

The narrator may gently notice the awkwardness or irony of the situation.
Allow small moments of quiet self-awareness.
Emotions can be mixed, but never crushing.
If the moment feels heavy, soften it with perspective.

Avoid heavy dramatic words: weight, crushing, ache, lump, resignation, dread.
Replace intensity with observation.
""";
    }
    return """
Writing tone:
Serious, calm, introspective.
Emotionally grounded.
""";
  }

  /// Build the user prompt
  static String _buildUserPrompt(String decision, String tone) {
    final toneModifier = _getToneModifier(tone);

    return """
**CRITICAL LANGUAGE RULE:**
The user wrote their decision in a specific language/dialect.
You MUST write your ENTIRE response in that EXACT same language.
- If they wrote in Tunisian Arabic (تونسي), write in Tunisian Arabic, NOT English, NOT formal Arabic.
- If they wrote in French, write in French.
- If they wrote in English, write in English.
- DETECT their language from the decision text below and MATCH IT EXACTLY.

$toneModifier

Decision (detect language from this):
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
- WRITE IN THE SAME LANGUAGE AS THE USER'S DECISION
- IMPORTANT: Output ONLY the two stories under the markers. Do NOT output checklists, word counts, self-evaluations, or commentary.

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
      throw Exception('Gemini API key not configured in .env');
    }

    String instruction = _systemPrompt;
    if (memoryContext != null && memoryContext.isNotEmpty) {
      instruction = '$_systemPrompt\n\n$memoryContext';
    }

    final requestBody = {
      "system_instruction": {
        "parts": [
          {"text": instruction}
        ]
      },
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": _buildUserPrompt(decision, tone)}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 2500,
        "thinkingConfig": {
          "thinkingBudget": 0,
        },
      }
    };

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response generated by Gemini');
    }

    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty content from Gemini');
    }

    final content = parts[0]['text'] as String;
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
      final patterns = ['IF YOU DO NOT ACT', 'IF YOU DON\'T ACT', '\n2)', '\n2.', '\n2:'];

      for (final pattern in patterns) {
        if (content.contains(pattern)) {
          final idx = content.indexOf(pattern);
          ifAct = content.substring(0, idx).trim();
          ifNot = content.substring(idx).trim();

          // Clean up
          final actPatterns = ['IF YOU ACT', '\n1)', '\n1.', '\n1:'];
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

    // Last resort: split in half
    if (ifAct.isEmpty && ifNot.isEmpty) {
      final mid = content.length ~/ 2;
      ifAct = content.substring(0, mid).trim();
      ifNot = content.substring(mid).trim();
    }

    // Sanitize any stray self-check or rule notes
    ifAct = _cleanTrailingCommentary(ifAct);
    ifNot = _cleanTrailingCommentary(ifNot);

    return {'ifAct': ifAct, 'ifNot': ifNot};
  }

  static String _cleanTrailingCommentary(String text) {
    final unwantedMarkers = [
      '\n\n* Word count',
      '\n\n* Story 1',
      '\n\n* Story 2',
      '\n\nRule check',
      '\n\nChecklist',
      '\n\nSelf-check',
      '\n\nNote:',
      '\n\nNotes:',
    ];
    String cleaned = text;
    for (final marker in unwantedMarkers) {
      final idx = cleaned.toLowerCase().indexOf(marker.toLowerCase());
      if (idx != -1) {
        cleaned = cleaned.substring(0, idx).trim();
      }
    }
    return cleaned;
  }
}
