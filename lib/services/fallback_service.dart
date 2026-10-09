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
You are a reflective fiction writer.

Your task is to explore two parallel futures based on a human decision.

Writing principles:
- Stay FOCUSED on the exact decision the user describes
- Grounded, realistic storytelling based on their situation
- Second person ("you")
- No advice. No judgment. No moral conclusion.
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
