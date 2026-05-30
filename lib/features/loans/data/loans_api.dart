import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../customers/data/customer_model.dart';
import 'loan_model.dart';

class LoansApi {
  const LoansApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<Loan>> listLoans({
    int page = 1,
    int pageSize = 20,
    String? status,
    int? customerId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/loans',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'status': status,
          'customerId': customerId,
        }..removeWhere((key, value) => value == null),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar los prestamos.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <Loan>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => Loan.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los prestamos.');
    }
  }

  Future<Loan> createLoan({
    required int customerId,
    required double principalAmount,
    required double interestRate,
    required String startDate,
    required String dueDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/loans',
        data: {
          'customerId': customerId,
          'principalAmount': principalAmount,
          'interestRate': interestRate,
          'startDate': startDate,
          'dueDate': dueDate,
        },
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo crear el prestamo.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return Loan.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo crear el prestamo.');
    }
  }

  Future<List<Customer>> listActiveCustomersForPicker() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customers',
        queryParameters: {'status': 'ACTIVE', 'page': 1, 'pageSize': 100},
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
