class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, code: $code, message: $message)';
  }
}
