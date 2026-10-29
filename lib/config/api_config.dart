class ApiConfig {
  static const String baseUrl = 'https://6ae1b4c9bbb5412922990697.mockapi.io';
  static const String resource = 'visitors';
  static const Duration timeout = Duration(seconds: 15);

  static bool get isConfigured =>
      baseUrl.startsWith('https://') &&
      baseUrl.contains('.mockapi.io') &&
      !baseUrl.toUpperCase().contains('https://6ae1b4c9bbb5412922990697.mockapi.io/');
}