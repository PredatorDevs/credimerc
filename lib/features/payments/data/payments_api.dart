import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'payment_model.dart';

class PaymentsApi {
  const PaymentsApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<Payment>> listLoanPayments(int loanId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/loans/$loanId/payments');

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success) {
        throw ApiException(
          message: envelope.message ?? 'No se pudieron cargar los pagos.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      final rawItems = envelope.data?['items'];
      if (rawItems is! List) {
        return const <Payment>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => Payment.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los pagos.');
    }
  }

  Future<Payment> createLoanPayment({
    required int loanId,
    required double amount,
    String paymentMethod = 'CASH',
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/loans/$loanId/payments',
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod,
          'referenceNumber': referenceNumber,
          'notes': notes,
        }..removeWhere((key, value) => value == null || value == ''),
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo registrar el pago.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return Payment.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo registrar el pago.');
    }
  }

  Future<Payment> voidPayment({
    required int paymentId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payments/$paymentId/void',
        data: {'reason': reason},
      );

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo anular el pago.',
          code: envelope.error,
          statusCode: response.statusCode,
          details: envelope.details,
        );
      }

      return Payment.fromMap(envelope.data!);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo anular el pago.');
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
