import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'permission_model.dart';
import 'role_model.dart';

class RbacApi {
  const RbacApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<PermissionItem>> listPermissions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/permissions');

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar los permisos.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <PermissionItem>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => PermissionItem.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los permisos.');
    }
  }

  Future<List<RoleItem>> listRoles() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/roles');

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar los roles.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <RoleItem>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => RoleItem.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los roles.');
    }
  }

  Future<RoleItem> createRole({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/roles',
        data: {
          'name': name,
          'description': description,
        }..removeWhere((key, value) => value == null || value == ''),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo crear el rol.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return RoleItem.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo crear el rol.');
    }
  }

  Future<void> setRolePermissions({
    required int roleId,
    required List<int> permissionIds,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/roles/$roleId/permissions',
        data: {'permissionIds': permissionIds},
      );
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron actualizar los permisos del rol.');
    }
  }

  Future<void> setCompanyUserRoles({
    required int companyUserId,
    required List<int> roleIds,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/company-users/$companyUserId/roles',
        data: {'roleIds': roleIds},
      );
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron actualizar los roles del usuario.');
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
