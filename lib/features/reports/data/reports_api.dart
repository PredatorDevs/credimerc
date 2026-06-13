import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';

class ReportsApi {
  const ReportsApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<PortfolioReport> getPortfolio() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reports/portfolio');
      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      return PortfolioReport.fromMap(body);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo cargar el reporte de cartera.');
    }
  }

  Future<List<OverdueLoanItem>> getOverdueLoans({int limit = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/overdue-loans',
        queryParameters: {'limit': limit},
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      final rawItems = body['items'];
      if (rawItems is! List) {
        return const <OverdueLoanItem>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => OverdueLoanItem.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo cargar el reporte de mora.');
    }
  }

  Future<DailyPaymentsReport> getDailyPayments({
    required String from,
    required String to,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/daily-payments',
        queryParameters: {'from': from, 'to': to},
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      return DailyPaymentsReport.fromMap(body);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo cargar el reporte de pagos diarios.');
    }
  }

  Future<CollectorPaymentsReport> getCollectorPayments({
    required String from,
    required String to,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/collector-payments',
        queryParameters: {'from': from, 'to': to},
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      return CollectorPaymentsReport.fromMap(body);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo cargar el reporte por cobrador.');
    }
  }

  Map<String, dynamic> _unwrapBody(Map<String, dynamic> body) {
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      body,
      (raw) => (raw as Map).cast<String, dynamic>(),
    );

    if (!envelope.success || envelope.data == null) {
      throw ApiException(
        message: envelope.message ?? 'No se pudo cargar el reporte.',
        code: envelope.error,
        details: envelope.details,
      );
    }

    return envelope.data!;
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

class PortfolioReport {
  const PortfolioReport({
    required this.totalPrincipalLoaned,
    required this.totalOutstanding,
    required this.totalCollectedToday,
    required this.activeLoans,
    required this.overdueLoans,
    required this.activeCustomers,
    required this.paymentsToday,
  });

  final double totalPrincipalLoaned;
  final double totalOutstanding;
  final double totalCollectedToday;
  final int activeLoans;
  final int overdueLoans;
  final int activeCustomers;
  final int paymentsToday;

  factory PortfolioReport.fromMap(Map<String, dynamic> map) {
    final totals = (map['totals'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final counters = (map['counters'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    return PortfolioReport(
      totalPrincipalLoaned: (totals['totalPrincipalLoaned'] as num?)?.toDouble() ?? 0,
      totalOutstanding: (totals['totalOutstanding'] as num?)?.toDouble() ?? 0,
      totalCollectedToday: (totals['totalCollectedToday'] as num?)?.toDouble() ?? 0,
      activeLoans: (counters['activeLoans'] as num?)?.toInt() ?? 0,
      overdueLoans: (counters['overdueLoans'] as num?)?.toInt() ?? 0,
      activeCustomers: (counters['activeCustomers'] as num?)?.toInt() ?? 0,
      paymentsToday: (counters['paymentsToday'] as num?)?.toInt() ?? 0,
    );
  }
}

class OverdueLoanItem {
  const OverdueLoanItem({
    required this.id,
    required this.loanNumber,
    required this.customerName,
    required this.dueDate,
    required this.balanceAmount,
    required this.daysOverdue,
  });

  final int id;
  final String loanNumber;
  final String customerName;
  final DateTime? dueDate;
  final double balanceAmount;
  final int daysOverdue;

  factory OverdueLoanItem.fromMap(Map<String, dynamic> map) {
    return OverdueLoanItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      loanNumber: map['loan_number']?.toString() ?? '-',
      customerName: map['customer_name']?.toString() ?? '-',
      dueDate: DateTime.tryParse(map['due_date']?.toString() ?? ''),
      balanceAmount: (map['balance_amount'] as num?)?.toDouble() ?? 0,
      daysOverdue: (map['days_overdue'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyPaymentsReport {
  const DailyPaymentsReport({
    required this.from,
    required this.to,
    required this.items,
  });

  final String from;
  final String to;
  final List<DailyPaymentItem> items;

  factory DailyPaymentsReport.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return DailyPaymentsReport(
      from: map['from']?.toString() ?? '',
      to: map['to']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => DailyPaymentItem.fromMap(item.cast<String, dynamic>()))
              .toList(growable: false)
          : const <DailyPaymentItem>[],
    );
  }
}

class DailyPaymentItem {
  const DailyPaymentItem({
    required this.day,
    required this.paymentsCount,
    required this.totalAmount,
  });

  final String day;
  final int paymentsCount;
  final double totalAmount;

  factory DailyPaymentItem.fromMap(Map<String, dynamic> map) {
    return DailyPaymentItem(
      day: map['day']?.toString() ?? '',
      paymentsCount: (map['paymentsCount'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CollectorPaymentsReport {
  const CollectorPaymentsReport({
    required this.from,
    required this.to,
    required this.items,
  });

  final String from;
  final String to;
  final List<CollectorPaymentItem> items;

  factory CollectorPaymentsReport.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return CollectorPaymentsReport(
      from: map['from']?.toString() ?? '',
      to: map['to']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => CollectorPaymentItem.fromMap(item.cast<String, dynamic>()))
              .toList(growable: false)
          : const <CollectorPaymentItem>[],
    );
  }
}

class CollectorPaymentItem {
  const CollectorPaymentItem({
    required this.collectorCompanyUserId,
    required this.collectorName,
    required this.paymentsCount,
    required this.totalAmount,
  });

  final int collectorCompanyUserId;
  final String collectorName;
  final int paymentsCount;
  final double totalAmount;

  factory CollectorPaymentItem.fromMap(Map<String, dynamic> map) {
    return CollectorPaymentItem(
      collectorCompanyUserId: (map['collectorCompanyUserId'] as num?)?.toInt() ?? 0,
      collectorName: map['collectorName']?.toString() ?? '-',
      paymentsCount: (map['paymentsCount'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
