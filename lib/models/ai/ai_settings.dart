enum AiProvider { openai }

class AiSettings {
  const AiSettings({
    this.provider = AiProvider.openai,
    this.model = 'gpt-4.1-mini',
    this.streamingEnabled = true,
    this.baseUrl = 'https://api.openai.com',
    this.hasApiKey = false,
    this.lastTestAtIso,
    this.lastTestSuccessful,
    this.lastTestMessage,
  });

  final AiProvider provider;
  final String model;
  final bool streamingEnabled;
  final String baseUrl;
  final bool hasApiKey;
  final String? lastTestAtIso;
  final bool? lastTestSuccessful;
  final String? lastTestMessage;

  bool get hasRecentTest => lastTestAtIso != null;

  AiSettings copyWith({
    AiProvider? provider,
    String? model,
    bool? streamingEnabled,
    String? baseUrl,
    bool? hasApiKey,
    String? lastTestAtIso,
    bool? lastTestSuccessful,
    String? lastTestMessage,
    bool clearTestResult = false,
  }) {
    return AiSettings(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
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
    final providerRaw = (json['provider'] as String?) ?? 'openai';
    return AiSettings(
      provider: providerRaw == 'openai' ? AiProvider.openai : AiProvider.openai,
      model: (json['model'] as String?)?.trim().isNotEmpty == true
          ? json['model'] as String
          : 'gpt-4.1-mini',
      streamingEnabled: json['streamingEnabled'] as bool? ?? true,
      baseUrl: (json['baseUrl'] as String?)?.trim().isNotEmpty == true
          ? json['baseUrl'] as String
          : 'https://api.openai.com',
      hasApiKey: json['hasApiKey'] as bool? ?? false,
      lastTestAtIso: json['lastTestAtIso'] as String?,
      lastTestSuccessful: json['lastTestSuccessful'] as bool?,
      lastTestMessage: json['lastTestMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'model': model,
      'streamingEnabled': streamingEnabled,
      'baseUrl': baseUrl,
      'hasApiKey': hasApiKey,
      'lastTestAtIso': lastTestAtIso,
      'lastTestSuccessful': lastTestSuccessful,
      'lastTestMessage': lastTestMessage,
    };
  }
}
