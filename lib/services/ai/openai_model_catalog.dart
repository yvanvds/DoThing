import 'dart:convert';
import 'dart:io';

/// The capability tier of a model variant.
enum ModelTier {
  /// Standard (full-size) variant.
  base,

  /// Reduced-size / speed-focused variant.
  mini,

  /// Smallest / cheapest variant.
  nano,
}

/// Parsed metadata for a single OpenAI chat-capable model.
class OpenAiModelInfo {
  const OpenAiModelInfo({
    required this.id,
    required this.familyLabel,
    required this.version,
    required this.tier,
    required this.isDatedSnapshot,
  });

  /// Raw model identifier returned by the API (e.g. `gpt-4.1-mini`).
  final String id;

  /// High-level family name: `'gpt'`, `'o'`, or `'chatgpt'`.
  final String familyLabel;

  /// Numeric version extracted from the model name (e.g. `4.1`, `3.0`).
  final double version;

  final ModelTier tier;

  /// True when the model id has a date-based snapshot suffix (e.g. `-2025-04-14`).
  final bool isDatedSnapshot;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) => other is OpenAiModelInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Pure service for fetching, filtering, ranking, and validating OpenAI models.
///
/// Contains no Riverpod code so it stays importable without circular deps.
class OpenAiModelCatalog {
  static final _datedSuffix = RegExp(r'-\d{4}-\d{2}-\d{2}$');

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  /// Returns `true` when [id] looks like a chat / reasoning text model.
  static bool isChatModel(String id) {
    final l = id.toLowerCase();

    // Quick exclusions – non-chat model families / keywords
    const excluded = [
      'embedding',
      'tts-',
      'whisper',
      'dall-e',
      'omni-moderation',
      'babbage',
      'davinci',
      '-instruct',
      'moderation',
      'audio',
      'realtime',
      'search',
    ];
    for (final ex in excluded) {
      if (l.contains(ex)) return false;
    }

    // Must start with a known chat-capable prefix
    if (l.startsWith('gpt-')) return true;
    if (l.startsWith('chatgpt-')) return true;
    if (RegExp(r'^o\d').hasMatch(l)) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parse [id] into [OpenAiModelInfo]. Returns `null` if not recognisable.
  static OpenAiModelInfo? parseModelInfo(String id) {
    if (!isChatModel(id)) return null;

    final isDated = _datedSuffix.hasMatch(id);
    final stripped = isDated ? id.replaceFirst(_datedSuffix, '') : id;
    final ls = stripped.toLowerCase();

    // Tier
    final ModelTier tier;
    if (ls.contains('-nano')) {
      tier = ModelTier.nano;
    } else if (ls.contains('-mini')) {
      tier = ModelTier.mini;
    } else {
      tier = ModelTier.base;
    }

    // Family + version
    final String familyLabel;
    final double version;

    if (ls.startsWith('gpt-')) {
      familyLabel = 'gpt';
      // gpt-4.1, gpt-3.5, gpt-4.5-preview, gpt-4-turbo …
      final numericMatch = RegExp(r'^gpt-(\d+(?:\.\d+)?)').firstMatch(ls);
      if (numericMatch != null) {
        version = double.tryParse(numericMatch.group(1)!) ?? 0;
      } else {
        // gpt-4o style (omni suffix – treat as 4.0)
        final omniMatch = RegExp(r'^gpt-(\d+)o').firstMatch(ls);
        if (omniMatch != null) {
          version = double.tryParse(omniMatch.group(1)!) ?? 0;
        } else {
          return null;
        }
      }
    } else if (ls.startsWith('chatgpt-')) {
      familyLabel = 'chatgpt';
      version = 4.0; // chatgpt-4o-latest is the gpt-4 omni family
    } else if (RegExp(r'^o\d').hasMatch(ls)) {
      familyLabel = 'o';
      final match = RegExp(r'^o(\d+(?:\.\d+)?)').firstMatch(ls);
      version = double.tryParse(match?.group(1) ?? '0') ?? 0;
    } else {
      return null;
    }

    return OpenAiModelInfo(
      id: id,
      familyLabel: familyLabel,
      version: version,
      tier: tier,
      isDatedSnapshot: isDated,
    );
  }

  // ---------------------------------------------------------------------------
  // Ranking & deduplication
  // ---------------------------------------------------------------------------

  /// Filter [rawIds] to chat models, drop dated snapshots that have a stable
  /// alias counterpart, and sort by relevance (higher version first, then tier).
  static List<OpenAiModelInfo> filterAndRank(List<String> rawIds) {
    final parsed = rawIds
        .map(parseModelInfo)
        .whereType<OpenAiModelInfo>()
        .toList();

    // Build a key set of stable aliases for fast lookup
    final aliasKeys = parsed
        .where((m) => !m.isDatedSnapshot)
        .map((m) => '${m.familyLabel}-${m.version}-${m.tier.name}')
        .toSet();

    final deduped = parsed.where((m) {
      if (!m.isDatedSnapshot) return true;
      // Drop dated snapshot when a stable alias covers the same slot
      final key = '${m.familyLabel}-${m.version}-${m.tier.name}';
      return !aliasKeys.contains(key);
    }).toList();

    deduped.sort((a, b) {
      // gpt family → o family → chatgpt family
      int familyRank(String f) => switch (f) {
        'gpt' => 0,
        'o' => 1,
        _ => 2,
      };
      final fComp = familyRank(
        a.familyLabel,
      ).compareTo(familyRank(b.familyLabel));
      if (fComp != 0) return fComp;

      // Higher version first
      final vComp = b.version.compareTo(a.version);
      if (vComp != 0) return vComp;

      // Tier: base(0) → mini(1) → nano(2)
      return a.tier.index.compareTo(b.tier.index);
    });

    return deduped;
  }

  // ---------------------------------------------------------------------------
  // Default selections
  // ---------------------------------------------------------------------------

  /// Best default complex (full-capability) model: highest-version base model.
  static OpenAiModelInfo? defaultComplex(List<OpenAiModelInfo> models) => models
      .where((m) => m.tier == ModelTier.base && !m.isDatedSnapshot)
      .firstOrNull;

  /// Best default fast model (mini tier), preferring the same
  /// family/version as [defaultComplex].
  static OpenAiModelInfo? defaultFast(List<OpenAiModelInfo> models) {
    final complex = defaultComplex(models);
    final minis = models.where(
      (m) => m.tier == ModelTier.mini && !m.isDatedSnapshot,
    );
    if (complex == null) return minis.firstOrNull;

    return minis
            .where(
              (m) =>
                  m.familyLabel == complex.familyLabel &&
                  m.version == complex.version,
            )
            .firstOrNull ??
        minis.where((m) => m.familyLabel == complex.familyLabel).firstOrNull ??
        minis.firstOrNull;
  }

  /// Best default cheap model (nano tier, then mini), preferring the same
  /// family/version as [defaultComplex].
  static OpenAiModelInfo? defaultCheap(List<OpenAiModelInfo> models) {
    final complex = defaultComplex(models);
    final nanos = models.where(
      (m) => m.tier == ModelTier.nano && !m.isDatedSnapshot,
    );

    if (complex == null) {
      return nanos.firstOrNull ??
          models
              .where((m) => m.tier == ModelTier.mini && !m.isDatedSnapshot)
              .firstOrNull;
    }

    return nanos
            .where(
              (m) =>
                  m.familyLabel == complex.familyLabel &&
                  m.version == complex.version,
            )
            .firstOrNull ??
        nanos.where((m) => m.familyLabel == complex.familyLabel).firstOrNull ??
        nanos.firstOrNull ??
        models
            .where(
              (m) =>
                  m.tier == ModelTier.mini &&
                  m.familyLabel == complex.familyLabel &&
                  m.version == complex.version &&
                  !m.isDatedSnapshot,
            )
            .firstOrNull;
  }

  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if [modelId] is present in [models].
  static bool isAvailable(String modelId, List<OpenAiModelInfo> models) =>
      models.any((m) => m.id == modelId);

  /// Returns `true` if [models] contains a non-snapshot model of the same
  /// tier and family as [selectedModelId] but with a higher version number.
  static bool isNewerFamilyAvailable(
    String selectedModelId,
    List<OpenAiModelInfo> models,
  ) {
    final selected = models.where((m) => m.id == selectedModelId).firstOrNull;
    if (selected == null) return false;

    return models.any(
      (m) =>
          !m.isDatedSnapshot &&
          m.familyLabel == selected.familyLabel &&
          m.tier == selected.tier &&
          m.version > selected.version,
    );
  }

  // ---------------------------------------------------------------------------
  // Network fetch
  // ---------------------------------------------------------------------------

  /// Fetch models from the OpenAI [baseUrl], returning filtered + ranked results.
  Future<List<OpenAiModelInfo>> fetchModels({
    required String apiKey,
    required String baseUrl,
  }) async {
    final normalised = baseUrl.trimRight().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalised/v1/models');

    final client = HttpClient();
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.headers
        ..set('Authorization', 'Bearer $apiKey')
        ..set('Content-Type', 'application/json');

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Unexpected HTTP ${response.statusCode} from /v1/models',
        );
      }

      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid models response');
      }

      final data = json['data'];
      if (data is! List) throw const FormatException('Missing data array');

      final ids = data
          .whereType<Map<String, dynamic>>()
          .map((m) => m['id'])
          .whereType<String>()
          .toList();

      return filterAndRank(ids);
    } finally {
      client.close(force: false);
    }
  }
}
