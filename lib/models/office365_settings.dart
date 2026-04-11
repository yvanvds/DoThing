class Office365AuthState {
  const Office365AuthState({
    this.accessToken = '',
    this.refreshToken = '',
    this.expiresAtIso = '',
    this.accountEmail = '',
    this.accountDisplayName = '',
  });

  final String accessToken;
  final String refreshToken;
  final String expiresAtIso;
  final String accountEmail;
  final String accountDisplayName;

  bool get hasToken => accessToken.trim().isNotEmpty;

  DateTime? get expiresAt {
    final raw = expiresAtIso.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Office365AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    String? expiresAtIso,
    String? accountEmail,
    String? accountDisplayName,
  }) => Office365AuthState(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAtIso: expiresAtIso ?? this.expiresAtIso,
    accountEmail: accountEmail ?? this.accountEmail,
    accountDisplayName: accountDisplayName ?? this.accountDisplayName,
  );
}

/// Immutable value object for Office 365 account and OAuth settings.
class Office365Settings {
  const Office365Settings({
    this.tenantId = '',
    this.clientId = '',
    this.redirectPort = 3141,
    this.scopes = 'offline_access openid profile Mail.Read',
    this.authState = const Office365AuthState(),
  });

  final String tenantId;
  final String clientId;
  final int redirectPort;
  final String scopes;
  final Office365AuthState authState;

  String get accessToken => authState.accessToken;
  String get refreshToken => authState.refreshToken;
  String get expiresAtIso => authState.expiresAtIso;
  String get accountEmail => authState.accountEmail;
  String get accountDisplayName => authState.accountDisplayName;

  bool get hasToken => authState.hasToken;

  DateTime? get expiresAt => authState.expiresAt;

  Office365Settings copyWith({
    String? tenantId,
    String? clientId,
    int? redirectPort,
    String? scopes,
    Office365AuthState? authState,
  }) => Office365Settings(
    tenantId: tenantId ?? this.tenantId,
    clientId: clientId ?? this.clientId,
    redirectPort: redirectPort ?? this.redirectPort,
    scopes: scopes ?? this.scopes,
    authState: authState ?? this.authState,
  );
}
