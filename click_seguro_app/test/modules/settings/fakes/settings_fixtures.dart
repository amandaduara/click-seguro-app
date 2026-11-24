/// JSON no formato real do servidor (R0 de specs/012-perfil e 013), com
/// valores fictícios.
Map<String, dynamic> accountJson({
  String name = 'Maria da Silva',
  String? avatarUrl,
  bool receiveNotifications = true,
}) => {
  'name': name,
  'email': 'maria@exemplo.com',
  'phone': null,
  'role': 'USER',
  'receiveNotifications': receiveNotifications,
  'avatarUrl': avatarUrl,
};

/// `POST /auth/app/login`.
Map<String, dynamic> tokensJson({
  String accessToken = 'acesso-novo',
  String refreshToken = 'renovacao-nova',
}) => {'accessToken': accessToken, 'refreshToken': refreshToken};
