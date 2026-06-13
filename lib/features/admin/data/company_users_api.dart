import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'company_user_model.dart';

class CompanyUsersApi {
  const CompanyUsersApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<CompanyUser>> listCompanyUsers({
    String? query,
    String? status,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/company-users',
        queryParameters: {
          'q': query,
          'status': status,
          'page': page,
          'pageSize': pageSize,
        }..removeWhere((key, value) => value == null),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar los usuarios de empresa.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <CompanyUser>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => CompanyUser.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los usuarios de empresa.');
    }
  }

  Future<CompanyUser> inviteCompanyUser({
    required String email,
    String? employeeCode,
    String? jobTitle,
    bool isOwner = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/company-users/invite',
        data: {
          'email': email,
          'employeeCode': employeeCode,
          'jobTitle': jobTitle,
          'isOwner': isOwner,
        }..removeWhere((key, value) => value == null || value == ''),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo invitar al usuario.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return CompanyUser.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo invitar al usuario.');
    }
  }

  Future<CompanyUser> updateCompanyUserStatus({
    required int companyUserId,
    required String status,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/company-users/$companyUserId',
        data: {'status': status},
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo actualizar el usuario.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return CompanyUser.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo actualizar el usuario.');
    }
  }

  Future<void> removeCompanyUser(int companyUserId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/company-users/$companyUserId');
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo remover al usuario.');
    }
  }

  ApiException _toApiException(DioException error, String fallbackMessage) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return ApiException(
        message: payload['message']?.toString() ?? fallbackMessage,
        code: payload['error']?.toString(),
        statusCode: error.response?.statusCode,
        details: payload['details'],
      );
    }

    return ApiException(
      message: error.message ?? fallbackMessage,
      statusCode: error.response?.statusCode,
    );
  }
}
