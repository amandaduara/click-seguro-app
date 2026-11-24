class EnvironmentConfig {
  /// Base da API, já com `/api/v1`. Sem `--dart-define=API_URL=...`, usa o
  /// servidor de desenvolvimento (não é segredo; ver api-contract.md).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://clickseguro-api.onrender.com/api/v1',
  );
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );
}
