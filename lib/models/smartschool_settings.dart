/// Immutable value object for Smartschool connection settings.
class SmartschoolSettings {
  const SmartschoolSettings({
    this.username = '',
    this.password = '',
    this.url = '',
    this.mfaSecret = '',
  });

  final String username;
  final String password;

  /// Base URL of the Smartschool instance, e.g. https://school.smartschool.be
  final String url;

  /// Google Authenticator secret key used to generate TOTP codes.
  final String mfaSecret;

  SmartschoolSettings copyWith({
    String? username,
    String? password,
    String? url,
    String? mfaSecret,
  }) => SmartschoolSettings(
    username: username ?? this.username,
    password: password ?? this.password,
    url: url ?? this.url,
    mfaSecret: mfaSecret ?? this.mfaSecret,
  );
}
