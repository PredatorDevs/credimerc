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

  Future<int> createCompany({
    required String name,
    String? commercialName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/companies',
        data: {
          'name': name,
          'commercialName': commercialName,
          'phone': phone,
          'email': email,
          'address': address,
        }..removeWhere((key, value) => value == null || value == ''),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo crear la empresa.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final companyId = (envelope.data!['id'] as num?)?.toInt();
      if (companyId == null || companyId <= 0) {
        throw ApiException(message: 'No se pudo obtener el id de la empresa creada.');
      }

      return companyId;
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        throw ApiException(
          message: payload['message']?.toString() ?? 'No se pudo crear la empresa.',
          code: payload['error']?.toString(),
          statusCode: error.response?.statusCode,
          details: payload['details'],
        );
      }

      throw ApiException(
        message: error.message ?? 'Error de red al crear empresa.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
