import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/services/intent_gatekeeper.dart';

void main() {
  group('IntentGatekeeper', () {
    
    // ═══════════════════════════════════════════════════════════════════════
    // REJECT TESTS - Trivial inputs that should be filtered
    // ═══════════════════════════════════════════════════════════════════════
    
    group('should REJECT trivial inputs', () {
      
      test('rejects "couscous or salad" (comparison without stakes)', () {
        final result = IntentGatekeeper.check('couscous or salad');
        expect(result.isValidDecision, isFalse);
        expect(result.rejectionMessage, isNotNull);
      });
      
      test('rejects "how to prepare couscous" (how-to question)', () {
        final result = IntentGatekeeper.check('how to prepare couscous');
        expect(result.isValidDecision, isFalse);
        expect(result.rejectionMessage, contains('how-to'));
      });
      
      test('rejects "what is the capital of France" (trivia)', () {
        final result = IntentGatekeeper.check('what is the capital of France');
        expect(result.isValidDecision, isFalse);
      });
      
      test('rejects "should I eat pizza or burger" (trivial choice)', () {
        final result = IntentGatekeeper.check('should I eat pizza or burger');
        expect(result.isValidDecision, isFalse);
        expect(result.rejectionMessage, contains('choice'));
      });
      
      test('rejects "what is the weather like" (no personal stakes)', () {
        final result = IntentGatekeeper.check('what is the weather like');
        expect(result.isValidDecision, isFalse);
      });
      
      test('rejects "should I watch Netflix or HBO" (trivial)', () {
        final result = IntentGatekeeper.check('should I watch Netflix or HBO');
        expect(result.isValidDecision, isFalse);
      });
      
      test('rejects random text without decision signals', () {
        final result = IntentGatekeeper.check('hello world this is a test');
        expect(result.isValidDecision, isFalse);
      });
      
    });
    
    // ═══════════════════════════════════════════════════════════════════════
    // ACCEPT TESTS - Genuine life decisions with emotional uncertainty
    // ═══════════════════════════════════════════════════════════════════════
    
    group('should ACCEPT genuine life decisions', () {
      
      test('accepts "I\'m not sure if I should quit my job"', () {
        final result = IntentGatekeeper.check(
          "I'm not sure if I should quit my job"
        );
        expect(result.isValidDecision, isTrue);
        expect(result.confidence, greaterThanOrEqualTo(0.7));
      });
      
      test('accepts "Should I move to another country?"', () {
        final result = IntentGatekeeper.check(
          'Should I move to another country?'
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts "I\'m thinking about leaving my relationship"', () {
        final result = IntentGatekeeper.check(
          "I'm thinking about leaving my relationship"
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts "I don\'t know if I should tell him the truth"', () {
        final result = IntentGatekeeper.check(
          "I don't know if I should tell him the truth"
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts "I\'m scared to start my own business"', () {
        final result = IntentGatekeeper.check(
          "I'm scared to start my own business"
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts "Should I forgive her after what happened?"', () {
        final result = IntentGatekeeper.check(
          'Should I forgive her after what happened?'
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts "I\'m hesitating to accept this job offer"', () {
        final result = IntentGatekeeper.check(
          "I'm hesitating to accept this job offer"
        );
        expect(result.isValidDecision, isTrue);
      });
      
    });
    
    // ═══════════════════════════════════════════════════════════════════════
    // ARABIC TESTS
    // ═══════════════════════════════════════════════════════════════════════
    
    group('should handle Arabic input', () {
      
      test('accepts Arabic decision with uncertainty', () {
        final result = IntentGatekeeper.check(
          'أنا مش عارف إذا لازم أسيب شغلي'
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts Tunisian Arabic decision', () {
        final result = IntentGatekeeper.check(
          'راني محتار إذا نمشي ولا نبقى'
        );
        expect(result.isValidDecision, isTrue);
      });
      
    });
    
    // ═══════════════════════════════════════════════════════════════════════
    // FRENCH TESTS
    // ═══════════════════════════════════════════════════════════════════════
    
    group('should handle French input', () {
      
      test('accepts French decision with uncertainty', () {
        final result = IntentGatekeeper.check(
          "Je ne suis pas sûr si je dois quitter mon travail"
        );
        expect(result.isValidDecision, isTrue);
      });
      
      test('accepts French decision with life verb', () {
        final result = IntentGatekeeper.check(
          "J'hésite à partir vivre à l'étranger"
        );
        expect(result.isValidDecision, isTrue);
      });
      
    });
    
    // ═══════════════════════════════════════════════════════════════════════
    // EDGE CASES
    // ═══════════════════════════════════════════════════════════════════════
    
    group('edge cases', () {
      
      test('empty string passes through (handled by other validators)', () {
        final result = IntentGatekeeper.check('');
        expect(result.isValidDecision, isTrue);
      });
      
      test('rejection messages are gentle and non-shaming', () {
        final result = IntentGatekeeper.check('pizza or burger');
        expect(result.rejectionMessage, isNotNull);
        // Should not contain harsh language
        expect(result.rejectionMessage!.toLowerCase(), isNot(contains('wrong')));
        expect(result.rejectionMessage!.toLowerCase(), isNot(contains('error')));
        expect(result.rejectionMessage!.toLowerCase(), isNot(contains('invalid')));
      });
      
      test('isValidDecision helper works correctly', () {
        expect(
          IntentGatekeeper.isValidDecision("I'm unsure if I should leave"),
          isTrue,
        );
        expect(
          IntentGatekeeper.isValidDecision('pizza or salad'),
          isFalse,
        );
      });
      
    });
    
    // ═══════════════════════════════════════════════════════════════════════
    // CONFIDENCE SCORING
    // ═══════════════════════════════════════════════════════════════════════
    
    group('confidence scoring', () {
      
      test('perfect match has highest confidence', () {
        final result = IntentGatekeeper.check(
          "I'm not sure if I should quit my job" // first person + uncertainty + life verb
        );
        expect(result.confidence, equals(1.0));
      });
      
      test('first person + life verb has high confidence', () {
        final result = IntentGatekeeper.check(
          "I want to leave my job" // first person + life verb, no explicit uncertainty
        );
        expect(result.confidence, greaterThanOrEqualTo(0.8));
      });
      
      test('rejected inputs have zero confidence', () {
        final result = IntentGatekeeper.check('pizza or salad');
        expect(result.confidence, equals(0.0));
      });
      
    });
    
  });
}
