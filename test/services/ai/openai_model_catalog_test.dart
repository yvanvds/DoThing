import 'package:do_thing/services/ai/openai_model_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // isChatModel
  // ---------------------------------------------------------------------------

  group('isChatModel', () {
    test('accepts gpt-4.1 family', () {
      expect(OpenAiModelCatalog.isChatModel('gpt-4.1'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('gpt-4.1-mini'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('gpt-4.1-nano'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('gpt-4.1-2025-04-14'), isTrue);
    });

    test('accepts gpt-4o family', () {
      expect(OpenAiModelCatalog.isChatModel('gpt-4o'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('gpt-4o-mini'), isTrue);
    });

    test('accepts o-reasoning models', () {
      expect(OpenAiModelCatalog.isChatModel('o1'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('o1-mini'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('o3'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('o3-mini'), isTrue);
      expect(OpenAiModelCatalog.isChatModel('o4-mini'), isTrue);
    });

    test('accepts chatgpt- family', () {
      expect(OpenAiModelCatalog.isChatModel('chatgpt-4o-latest'), isTrue);
    });

    test('rejects embedding models', () {
      expect(OpenAiModelCatalog.isChatModel('text-embedding-3-small'), isFalse);
      expect(OpenAiModelCatalog.isChatModel('text-embedding-ada-002'), isFalse);
    });

    test('rejects TTS models', () {
      expect(OpenAiModelCatalog.isChatModel('tts-1'), isFalse);
      expect(OpenAiModelCatalog.isChatModel('tts-1-hd'), isFalse);
    });

    test('rejects whisper models', () {
      expect(OpenAiModelCatalog.isChatModel('whisper-1'), isFalse);
    });

    test('rejects dall-e models', () {
      expect(OpenAiModelCatalog.isChatModel('dall-e-3'), isFalse);
      expect(OpenAiModelCatalog.isChatModel('dall-e-2'), isFalse);
    });

    test('rejects moderation models', () {
      expect(OpenAiModelCatalog.isChatModel('omni-moderation-latest'), isFalse);
      expect(OpenAiModelCatalog.isChatModel('text-moderation-latest'), isFalse);
    });

    test('rejects legacy completion models', () {
      expect(OpenAiModelCatalog.isChatModel('babbage-002'), isFalse);
      expect(OpenAiModelCatalog.isChatModel('davinci-002'), isFalse);
    });

    test('rejects instruct models', () {
      expect(OpenAiModelCatalog.isChatModel('gpt-3.5-turbo-instruct'), isFalse);
    });

    test('rejects unknown models', () {
      expect(OpenAiModelCatalog.isChatModel('some-random-model'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // parseModelInfo
  // ---------------------------------------------------------------------------

  group('parseModelInfo', () {
    test('parses gpt-4.1 as base tier, version 4.1', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4.1')!;
      expect(info.id, 'gpt-4.1');
      expect(info.familyLabel, 'gpt');
      expect(info.version, 4.1);
      expect(info.tier, ModelTier.base);
      expect(info.isDatedSnapshot, isFalse);
    });

    test('parses gpt-4.1-mini as mini tier', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4.1-mini')!;
      expect(info.tier, ModelTier.mini);
      expect(info.version, 4.1);
    });

    test('parses gpt-4.1-nano as nano tier', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4.1-nano')!;
      expect(info.tier, ModelTier.nano);
      expect(info.version, 4.1);
    });

    test('parses dated snapshot correctly', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4.1-2025-04-14')!;
      expect(info.isDatedSnapshot, isTrue);
      expect(info.tier, ModelTier.base);
      expect(info.version, 4.1);
    });

    test('parses dated snapshot with tier', () {
      final info = OpenAiModelCatalog.parseModelInfo(
        'gpt-4.1-mini-2025-04-14',
      )!;
      expect(info.isDatedSnapshot, isTrue);
      expect(info.tier, ModelTier.mini);
      expect(info.version, 4.1);
    });

    test('parses gpt-4o as version 4.0 base', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4o')!;
      expect(info.familyLabel, 'gpt');
      expect(info.version, 4.0);
      expect(info.tier, ModelTier.base);
    });

    test('parses gpt-4o-mini as version 4.0 mini', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-4o-mini')!;
      expect(info.tier, ModelTier.mini);
      expect(info.version, 4.0);
    });

    test('parses gpt-3.5-turbo as version 3.5 base', () {
      final info = OpenAiModelCatalog.parseModelInfo('gpt-3.5-turbo')!;
      expect(info.version, 3.5);
      expect(info.tier, ModelTier.base);
    });

    test('parses o3 as version 3.0 base', () {
      final info = OpenAiModelCatalog.parseModelInfo('o3')!;
      expect(info.familyLabel, 'o');
      expect(info.version, 3.0);
      expect(info.tier, ModelTier.base);
    });

    test('parses o3-mini as mini tier', () {
      final info = OpenAiModelCatalog.parseModelInfo('o3-mini')!;
      expect(info.familyLabel, 'o');
      expect(info.tier, ModelTier.mini);
    });

    test('returns null for non-chat model', () {
      expect(
        OpenAiModelCatalog.parseModelInfo('text-embedding-3-small'),
        isNull,
      );
      expect(OpenAiModelCatalog.parseModelInfo('whisper-1'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // filterAndRank – deduplication
  // ---------------------------------------------------------------------------

  group('filterAndRank deduplication', () {
    test('drops dated snapshot when stable alias exists', () {
      final raw = ['gpt-4.1', 'gpt-4.1-2025-04-14'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result.map((m) => m.id), equals(['gpt-4.1']));
    });

    test('keeps dated snapshot when no alias exists', () {
      final raw = ['gpt-4.1-2025-04-14'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result, hasLength(1));
      expect(result.first.isDatedSnapshot, isTrue);
    });

    test('drops dated mini snapshot when alias exists', () {
      final raw = ['gpt-4.1-mini', 'gpt-4.1-mini-2025-04-14'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result.map((m) => m.id), equals(['gpt-4.1-mini']));
    });

    test('excludes non-chat models from results', () {
      final raw = ['gpt-4.1', 'text-embedding-3-small', 'whisper-1'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result, hasLength(1));
      expect(result.first.id, 'gpt-4.1');
    });
  });

  // ---------------------------------------------------------------------------
  // filterAndRank – sorting
  // ---------------------------------------------------------------------------

  group('filterAndRank sorting', () {
    test('puts higher version before lower version within same family', () {
      final raw = ['gpt-3.5-turbo', 'gpt-4.1', 'gpt-4o'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      final versions = result.map((m) => m.version).toList();
      expect(versions.first, greaterThan(versions.last));
    });

    test('puts gpt family before o family', () {
      final raw = ['o3', 'gpt-4.1'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result.first.familyLabel, 'gpt');
    });

    test('puts base before mini before nano within same version', () {
      final raw = ['gpt-4.1-nano', 'gpt-4.1-mini', 'gpt-4.1'];
      final result = OpenAiModelCatalog.filterAndRank(raw);
      expect(result[0].tier, ModelTier.base);
      expect(result[1].tier, ModelTier.mini);
      expect(result[2].tier, ModelTier.nano);
    });
  });

  // ---------------------------------------------------------------------------
  // Default selections
  // ---------------------------------------------------------------------------

  group('defaultComplex', () {
    test('returns highest version base model', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-3.5-turbo',
        'gpt-4.1',
        'gpt-4.1-mini',
      ]);
      final result = OpenAiModelCatalog.defaultComplex(models);
      expect(result?.id, 'gpt-4.1');
    });

    test('returns null when no base models exist', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1-mini']);
      expect(OpenAiModelCatalog.defaultComplex(models), isNull);
    });
  });

  group('defaultFast', () {
    test('returns mini of same family/version as complex', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-4.1-mini',
        'gpt-3.5-turbo',
      ]);
      final result = OpenAiModelCatalog.defaultFast(models);
      expect(result?.id, 'gpt-4.1-mini');
    });

    test('falls back to any mini if no matching version mini exists', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-3.5-turbo-mini', // hypothetical older mini
      ]);
      // gpt-3.5-turbo-mini doesn't exist in real API but tests the fallback path
      final result = OpenAiModelCatalog.defaultFast(models);
      expect(result?.tier, ModelTier.mini);
    });

    test('returns null when no mini models exist', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1']);
      expect(OpenAiModelCatalog.defaultFast(models), isNull);
    });
  });

  group('defaultCheap', () {
    test('returns nano of same family/version as complex', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-4.1-mini',
        'gpt-4.1-nano',
      ]);
      final result = OpenAiModelCatalog.defaultCheap(models);
      expect(result?.id, 'gpt-4.1-nano');
    });

    test('falls back to mini when no nano exists for same version', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-4.1-mini',
      ]);
      final result = OpenAiModelCatalog.defaultCheap(models);
      expect(result?.id, 'gpt-4.1-mini');
    });

    test('returns null when no nano or mini exists', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1']);
      expect(OpenAiModelCatalog.defaultCheap(models), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // isAvailable
  // ---------------------------------------------------------------------------

  group('isAvailable', () {
    late List<OpenAiModelInfo> models;

    setUp(() {
      models = OpenAiModelCatalog.filterAndRank(['gpt-4.1', 'gpt-4.1-mini']);
    });

    test('returns true for present model', () {
      expect(OpenAiModelCatalog.isAvailable('gpt-4.1', models), isTrue);
    });

    test('returns false for absent model', () {
      expect(OpenAiModelCatalog.isAvailable('gpt-5.0', models), isFalse);
    });

    test('returns false for empty list', () {
      expect(OpenAiModelCatalog.isAvailable('gpt-4.1', []), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isNewerFamilyAvailable
  // ---------------------------------------------------------------------------

  group('isNewerFamilyAvailable', () {
    test('returns true when higher version of same family/tier exists', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1', 'gpt-4.5']);
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-4.1', models),
        isTrue,
      );
    });

    test('returns false when no higher version exists', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1']);
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-4.1', models),
        isFalse,
      );
    });

    test('returns false when selected model is not in list', () {
      final models = OpenAiModelCatalog.filterAndRank(['gpt-4.1']);
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-5.0', models),
        isFalse,
      );
    });

    test('ignores dated snapshots when detecting newer family', () {
      // If only a dated snapshot of a newer version exists (no alias),
      // it should still count as newer.
      final raw = ['gpt-4.1', 'gpt-4.5-2025-04-14'];
      final models = OpenAiModelCatalog.filterAndRank(raw);
      // gpt-4.5-2025-04-14 is kept (no alias) but isDatedSnapshot=true
      // isNewerFamilyAvailable checks !isDatedSnapshot, so should return false
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-4.1', models),
        isFalse,
      );
    });

    test('does not confuse different tiers', () {
      // gpt-4.5-mini is newer version but is mini tier, not base
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-4.5-mini',
      ]);
      // selected is base, candidate is mini → different tier, no match
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-4.1', models),
        isFalse,
      );
    });

    test('detects newer mini for mini selection', () {
      final models = OpenAiModelCatalog.filterAndRank([
        'gpt-4.1',
        'gpt-4.1-mini',
        'gpt-4.5',
        'gpt-4.5-mini',
      ]);
      expect(
        OpenAiModelCatalog.isNewerFamilyAvailable('gpt-4.1-mini', models),
        isTrue,
      );
    });
  });
}
