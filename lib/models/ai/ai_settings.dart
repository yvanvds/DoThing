enum AiProvider { openai }

class AiSettings {
  const AiSettings({
    this.provider = AiProvider.openai,
    this.complexModel = 'gpt-5.4',
    this.fastModel = 'gpt-5.4-mini',
    this.cheapModel = 'gpt-5.4-nano',
    this.chatModelPreset = 'complex',
    this.streamingEnabled = true,
    this.showAgentReasoning = false,
    this.baseUrl = 'https://api.openai.com',
    this.hasApiKey = false,
    this.lastTestAtIso,
    this.lastTestSuccessful,
    this.lastTestMessage,
  });

  final AiProvider provider;

  /// Full-capability model used for complex tasks and general chat.
  final String complexModel;

  /// Speed-focused (mini) model for latency-sensitive operations.
  final String fastModel;

  /// Cheapest (nano / smallest) model for cost-sensitive operations.
  final String cheapModel;

  /// Preferred chat preset used by the quick model toggle in the chat panel.
  final String chatModelPreset;

  final bool streamingEnabled;

  /// When true, the agent planner preamble (intent, domains, risk) is
  /// prepended to assistant messages so the user can see the reasoning.
  /// Clarifying questions are always shown regardless of this flag.
  final bool showAgentReasoning;
  final String baseUrl;
  final bool hasApiKey;
  final String? lastTestAtIso;
  final bool? lastTestSuccessful;
  final String? lastTestMessage;

  /// Backward-compatible alias used by chat and connection-test logic.
  String get model => complexModel;

  bool get hasRecentTest => lastTestAtIso != null;

  AiSettings copyWith({
    AiProvider? provider,
    String? complexModel,
    String? fastModel,
    String? cheapModel,
    String? chatModelPreset,
    bool? streamingEnabled,
    bool? showAgentReasoning,
    String? baseUrl,
    bool? hasApiKey,
    String? lastTestAtIso,
    bool? lastTestSuccessful,
    String? lastTestMessage,
    bool clearTestResult = false,
  }) {
    return AiSettings(
      provider: provider ?? this.provider,
      complexModel: complexModel ?? this.complexModel,
      fastModel: fastModel ?? this.fastModel,
      cheapModel: cheapModel ?? this.cheapModel,
      chatModelPreset: chatModelPreset ?? this.chatModelPreset,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      showAgentReasoning: showAgentReasoning ?? this.showAgentReasoning,
      baseUrl: baseUrl ?? this.baseUrl,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      lastTestAtIso: clearTestResult
          ? null
          : (lastTestAtIso ?? this.lastTestAtIso),
      lastTestSuccessful: clearTestResult
          ? null
          : (lastTestSuccessful ?? this.lastTestSuccessful),
      lastTestMessage: clearTestResult
          ? null
          : (lastTestMessage ?? this.lastTestMessage),
    );
  }

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    // Migration: if complexModel is absent, fall back to the legacy 'model' field.
    final legacyModel = (json['model'] as String?)?.trim().isNotEmpty == true
        ? json['model'] as String
        : null;

    String nonEmpty(String? raw, String fallback) =>
        (raw?.trim().isNotEmpty == true) ? raw! : fallback;

    final providerRaw = (json['provider'] as String?) ?? 'openai';
    return AiSettings(
      provider: providerRaw == 'openai' ? AiProvider.openai : AiProvider.openai,
      complexModel: nonEmpty(
        json['complexModel'] as String?,
        legacyModel ?? 'gpt-5.4',
      ),
      fastModel: nonEmpty(json['fastModel'] as String?, 'gpt-5.4-mini'),
      cheapModel: nonEmpty(json['cheapModel'] as String?, 'gpt-5.4-nano'),
      chatModelPreset: nonEmpty(json['chatModelPreset'] as String?, 'complex'),
      streamingEnabled: json['streamingEnabled'] as bool? ?? true,
      showAgentReasoning: json['showAgentReasoning'] as bool? ?? false,
      baseUrl: nonEmpty(json['baseUrl'] as String?, 'https://api.openai.com'),
      hasApiKey: json['hasApiKey'] as bool? ?? false,
      lastTestAtIso: json['lastTestAtIso'] as String?,
      lastTestSuccessful: json['lastTestSuccessful'] as bool?,
      lastTestMessage: json['lastTestMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'complexModel': complexModel,
      'fastModel': fastModel,
      'cheapModel': cheapModel,
      'chatModelPreset': chatModelPreset,
      'streamingEnabled': streamingEnabled,
      'showAgentReasoning': showAgentReasoning,
      'baseUrl': baseUrl,
      'hasApiKey': hasApiKey,
      'lastTestAtIso': lastTestAtIso,
      'lastTestSuccessful': lastTestSuccessful,
      'lastTestMessage': lastTestMessage,
    };
  }
}
