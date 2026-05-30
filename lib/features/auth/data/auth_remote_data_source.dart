import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'auth_models.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'skipAuth': true},
        ),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'Unable to refresh session.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return AuthTokens.fromMap(envelope.data!);
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ApiException(
          message: payload['message']?.toString() ?? 'Unable to refresh session.',
          code: payload['error']?.toString(),
          statusCode: error.response?.statusCode,
          details: payload['details'],
        );
      }

      throw ApiException(
        message: error.message ?? 'Network error while refreshing token.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
