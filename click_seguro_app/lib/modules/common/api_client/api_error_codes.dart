/// Códigos de negócio da API (campo `code` do corpo de erro) que o próprio
/// `common` usa para decidir sobre a sessão. Os códigos de cada feature
/// (ex.: `USER_EMAIL_ALREADY_EXISTS`) ficam no repository dela.
abstract final class ApiErrorCodes {
  /// E-mail/senha ou senha atual incorretos: nunca encerra a sessão.
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  /// Conta desativada: encerra a sessão como expirada.
  static const String userNotFound = 'USER_NOT_FOUND';
}
