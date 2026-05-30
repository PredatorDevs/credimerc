class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.data,
    required this.message,
    required this.meta,
    required this.error,
    required this.details,
  });

  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;
  final String? error;
  final dynamic details;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw)? fromData,
  ) {
    final hasData = json.containsKey('data') && json['data'] != null;

    return ApiEnvelope<T>(
      success: json['success'] == true,
      data: hasData
          ? (fromData != null ? fromData(json['data']) : json['data'] as T?)
          : null,
      message: json['message'] as String?,
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
      error: json['error'] as String?,
      details: json['details'],
    );
  }
}
