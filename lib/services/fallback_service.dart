import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenRouter Fallback Service
/// Activated when primary AI fails (quota, timeout, etc.)
class FallbackService {
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "nvidia/nemotron-3-super-120b-a12b:free";

  static const int _maxTokens = 1800;
  static const double _temperature = 0.7;
  static const Duration _timeout = Duration(seconds: 45);

  /// Get API key from environment
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// System prompt
  static const String _systemPrompt = """
You write realistic future scenarios based on a person's dream and concrete actions.

CRITICAL PRINCIPLES:
- Be realistic, concrete and calm. No hype, clichés, guarantees, predictions, scores, or percentages.
- The main scenario follows the user's actions and includes one realistic obstacle and how they get through it.
- Match the exact language and dialect of the user's input: Derja, French, English, or Arabic.
- Do not invent unrelated contexts or proper names.
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
  static String _buildUserPrompt(
    String dream,
    List<String> actions,
    String tone,
  ) {
    final toneModifier = _getToneModifier(tone);

    return """
**CRITICAL LANGUAGE RULE:**
Write in the EXACT SAME LANGUAGE/DIALECT as the dream below (Derja, French, English, or Arabic).

$toneModifier

Dream:
$dream

Actions the user plans:
${actions.map((a) => '- $a').join('\n')}

Write a reasonably brief grounded future scenario, then a second scenario about 40% as long describing what may continue if nothing changes. Both are second person and in the input's language/dialect. Do not imply certainty or guaranteed success.

Format EXACTLY as:
===STORY_ACT===
[story in user's language]

===STORY_NOT===
[story in user's language]
""";
  }

  /// Generate parallel futures
  Future<Map<String, String>> generateFutures({
    required String dream,
    required List<String> actions,
    String tone = 'reflective',
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
            'HTTP-Referer': 'https://ufuq.app',
            'X-Title': 'Ufuq',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {
                'role': 'user',
                'content': _buildUserPrompt(dream, actions, tone),
              },
            ],
            'max_tokens': _maxTokens,
            'temperature': _temperature,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No choices returned by OpenRouter');
    }

    final choice = Map<String, dynamic>.from(choices[0] as Map);
    final message = Map<String, dynamic>.from(
      choice['message'] as Map? ?? const {},
    );
    final rawContent = message['content'];
    final content = rawContent is List
        ? rawContent
              .whereType<Map>()
              .map((part) => part['text']?.toString() ?? '')
              .join('\n')
              .trim()
        : rawContent?.toString().trim() ?? '';

    if (content.trim().isEmpty) {
      final finishReason = choice['finish_reason']?.toString() ?? 'unknown';
      throw Exception(
        'OpenRouter returned no text (finish reason: $finishReason). Try again or check the fallback model/key.',
      );
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
