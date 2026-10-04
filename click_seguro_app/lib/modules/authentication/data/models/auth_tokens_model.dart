/// Corpo de `POST /auth/app/login` (AuthTokensResponseDto).
class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String;
    final refreshToken = json['refreshToken'] as String;
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Token vazio na resposta de login');
    }
    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  final String accessToken;
  final String refreshToken;
}
