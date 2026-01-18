import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenRouter Fallback Service
/// Activated when OpenAI fails (quota, timeout, etc.)
/// User never sees the fallback - seamless switch
class FallbackService {
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "meta-llama/llama-3.3-70b-instruct:free";

  static const int _maxTokens = 900;
  static const double _temperature = 0.7;
  static const Duration _timeout = Duration(seconds: 45);

  /// Get API key from environment
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// System prompt - same as primary
  static const String _systemPrompt = """
You are a reflective fiction writer.

Your task is to explore two parallel futures based on a human decision.

Writing principles:
- Stay FOCUSED on the exact decision the user describes
- Do NOT add random details (seasons, weather, time of day) unless the user mentioned them
- Do NOT invent context that wasn't in the question
- Grounded, realistic storytelling based on THEIR situation
- Emotions shown through actions and moments
- Calm, intimate tone
- No melodrama, no fantasy

You do not give advice.
You do not judge.
You do not recommend.
""";

  /// Tone modifiers
  static String _getToneModifier(String tone) {
    if (tone == 'light') {
      return """
Writing tone:
Warm and gently humorous.
Soft, human lightness.
No sarcasm.
No ridicule.
No exaggeration.
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
- 250–400 words per story
- Second person ("you")
- No moral conclusion
- No advice
- Focus on realistic consequences over time
- Keep the tone human and believable
- WRITE IN THE SAME LANGUAGE AS THE USER'S DECISION

Format EXACTLY as:
===STORY_ACT===
[story in user's language]

===STORY_NOT===
[story in user's language]
""";
  }

  /// Generate parallel futures using OpenRouter
  /// Optional memoryContext adds subtle continuity awareness
  Future<Map<String, String>> generateFutures({
    required String decision,
    required String tone,
    String? memoryContext,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key not configured');
    }

    // Build system prompt with optional memory context
    String systemPrompt = _systemPrompt;
    if (memoryContext != null) {
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
      throw Exception('OpenRouter API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;

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
      final patterns = [
        'IF YOU DO NOT ACT',
        'IF YOU DON\'T ACT',
        '2)',
        '2.',
      ];

      for (final pattern in patterns) {
        if (content.contains(pattern)) {
          final idx = content.indexOf(pattern);
          ifAct = content.substring(0, idx).trim();
          ifNot = content.substring(idx).trim();

          // Clean up
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

    // Last resort: split in half
    if (ifAct.isEmpty && ifNot.isEmpty) {
      final mid = content.length ~/ 2;
      ifAct = content.substring(0, mid).trim();
      ifNot = content.substring(mid).trim();
    }

    return {
      'ifAct': ifAct,
      'ifNot': ifNot,
    };
  }
}
