import '../../../core/session/auth_session.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  AuthSession toSession() => AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  factory AuthTokens.fromMap(Map<String, dynamic> map) {
    return AuthTokens(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      expiresInSeconds: (map['expiresInSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
