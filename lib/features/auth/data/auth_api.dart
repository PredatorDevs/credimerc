import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_store.dart';
import 'auth_models.dart';

class AuthApi {
  const AuthApi({
    required Dio dio,
    required SessionStore sessionStore,
  })  : _dio = dio,
        _sessionStore = sessionStore;

  final Dio _dio;
  final SessionStore _sessionStore;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final envelope = await _postEnvelope<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      },
      fromData: (raw) => (raw as Map).cast<String, dynamic>(),
      skipAuth: true,
    );

    return envelope.data ?? <String, dynamic>{};
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _postEnvelope<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      fromData: (raw) => (raw as Map).cast<String, dynamic>(),
      skipAuth: true,
    );

    final tokens = AuthTokens.fromMap(envelope.data ?? <String, dynamic>{});
    await _sessionStore.write(tokens.toSession());
    return tokens;
  }

  Future<void> logout() async {
    final session = await _sessionStore.read();
    if (session == null) {
      return;
    }

    try {
      await _postEnvelope<Map<String, dynamic>>(
        '/auth/logout',
        data: {'refreshToken': session.refreshToken},
        fromData: (raw) => raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{},
      );
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<Map<String, dynamic>> me() async {
    final envelope = await _getEnvelope<Map<String, dynamic>>(
      '/auth/me',
      fromData: (raw) => (raw as Map).cast<String, dynamic>(),
    );

    return envelope.data ?? <String, dynamic>{};
  }

  Future<AuthTokens> selectCompany(int companyId) async {
    final envelope = await _postEnvelope<Map<String, dynamic>>(
      '/auth/select-company',
      data: {'companyId': companyId},
      fromData: (raw) => (raw as Map).cast<String, dynamic>(),
    );

    final data = envelope.data ?? <String, dynamic>{};

    final current = await _sessionStore.read();
    final next = AuthTokens(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: current?.refreshToken ?? '',
      expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt() ?? 0,
    );

    await _sessionStore.write(next.toSession());
    return next;
  }

  Future<void> forgotPassword({required String email}) async {
    await _postEnvelope<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
      fromData: (raw) => raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{},
      skipAuth: true,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _postEnvelope<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
      fromData: (raw) => raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{},
      skipAuth: true,
    );
  }

  Future<ApiEnvelope<T>> _postEnvelope<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(Object? raw) fromData,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(extra: {'skipAuth': skipAuth}),
      );

      final envelope = ApiEnvelope<T>.fromJson(response.data ?? <String, dynamic>{}, fromData);
      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'Request failed.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return envelope;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<ApiEnvelope<T>> _getEnvelope<T>(
    String path, {
    required T Function(Object? raw) fromData,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(extra: {'skipAuth': skipAuth}),
      );

      final envelope = ApiEnvelope<T>.fromJson(response.data ?? <String, dynamic>{}, fromData);
      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'Request failed.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return envelope;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return ApiException(
        message: payload['message']?.toString() ?? 'Request failed.',
        code: payload['error']?.toString(),
        statusCode: error.response?.statusCode,
        details: payload['details'],
      );
    }

    return ApiException(
      message: error.message ?? 'Network request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}
