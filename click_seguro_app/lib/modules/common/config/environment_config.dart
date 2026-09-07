class EnvironmentConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
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
