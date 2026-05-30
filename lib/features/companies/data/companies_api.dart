import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'company_membership.dart';

class CompaniesApi {
  const CompaniesApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<CompanyMembership>> listMyCompanies() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/companies');

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar las empresas.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <CompanyMembership>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => CompanyMembership.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ApiException(
          message: payload['message']?.toString() ?? 'No se pudieron cargar las empresas.',
          code: payload['error']?.toString(),
          statusCode: error.response?.statusCode,
          details: payload['details'],
        );
      }

      throw ApiException(
        message: error.message ?? 'Error de red al obtener empresas.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
