class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://192.168.2.17:5001/api',
    defaultValue: 'https://credimerc.vercel.app/api'
  );
}
