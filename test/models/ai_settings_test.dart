import 'package:do_thing/models/ai/ai_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSettings', () {
    test('defaults include complex chat preset', () {
      const settings = AiSettings();
      expect(settings.chatModelPreset, 'complex');
    });

    test('fromJson reads chatModelPreset and keeps model fields', () {
      final settings = AiSettings.fromJson({
        'provider': 'openai',
        'complexModel': 'gpt-5.4',
        'fastModel': 'gpt-5.4-mini',
        'cheapModel': 'gpt-5.4-nano',
        'chatModelPreset': 'cheap',
        'streamingEnabled': true,
        'baseUrl': 'https://api.openai.com',
        'hasApiKey': true,
      });

      expect(settings.chatModelPreset, 'cheap');
      expect(settings.complexModel, 'gpt-5.4');
      expect(settings.fastModel, 'gpt-5.4-mini');
      expect(settings.cheapModel, 'gpt-5.4-nano');
    });

    test('toJson includes chatModelPreset', () {
      const settings = AiSettings(chatModelPreset: 'default');
      final json = settings.toJson();

      expect(json['chatModelPreset'], 'default');
    });

    test('defaults showAgentReasoning to false', () {
      const settings = AiSettings();
      expect(settings.showAgentReasoning, isFalse);
    });

    test('round-trips showAgentReasoning through JSON', () {
      const settings = AiSettings(showAgentReasoning: true);
      final json = settings.toJson();
      expect(json['showAgentReasoning'], isTrue);

      final restored = AiSettings.fromJson(json);
      expect(restored.showAgentReasoning, isTrue);
    });

    test('copyWith updates chatModelPreset only', () {
      const base = AiSettings(
        complexModel: 'gpt-5.4',
        fastModel: 'gpt-5.4-mini',
        cheapModel: 'gpt-5.4-nano',
        chatModelPreset: 'complex',
      );

      final updated = base.copyWith(chatModelPreset: 'cheap');

      expect(updated.chatModelPreset, 'cheap');
      expect(updated.complexModel, base.complexModel);
      expect(updated.fastModel, base.fastModel);
      expect(updated.cheapModel, base.cheapModel);
    });
  });
}
