import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'customer_model.dart';

class CustomersApi {
  const CustomersApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<Customer>> listCustomers({
    String? query,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers',
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
          message: envelope.message ?? 'No se pudieron cargar los clientes.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <Customer>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => Customer.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los clientes.');
    }
  }

  Future<Customer> createCustomer({
    required String firstName,
    String? lastName,
    String? documentType,
    String? documentNumber,
    String? phone,
    String? email,
    String? businessName,
    String? marketName,
    String? marketSector,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'documentType': documentType,
          'documentNumber': documentNumber,
          'phone': phone,
          'email': email,
          'businessName': businessName,
          'marketName': marketName,
          'marketSector': marketSector,
          'notes': notes,
        }..removeWhere((key, value) => value == null || value == ''),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo crear el cliente.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return Customer.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo crear el cliente.');
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
