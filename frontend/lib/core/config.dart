class AppConfig {
  AppConfig._();

  static const String appName = 'Hexbase Retail';

  // Base URL can be overridden per environment
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String tenantCode = String.fromEnvironment(
    'TENANT_CODE',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
