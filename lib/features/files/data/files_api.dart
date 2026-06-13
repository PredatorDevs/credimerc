import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import 'attachment_model.dart';

class FilesApi {
  FilesApi({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;
  final Dio _uploadDio = Dio();

  Future<List<AttachmentItem>> listFiles({
    required String ownerType,
    required int ownerId,
    String? category,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/files',
        queryParameters: {
          'ownerType': ownerType,
          'ownerId': ownerId,
          'category': category,
        }..removeWhere((key, value) => value == null),
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      final rawItems = body['items'];
      if (rawItems is! List) {
        return const <AttachmentItem>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => AttachmentItem.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudieron cargar los adjuntos.');
    }
  }

  Future<AttachmentItem> uploadAttachment({
    required String ownerType,
    required int ownerId,
    required String category,
    required String mimeType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    UploadTicket? ticket;
    try {
      ticket = await _createUploadUrl(
        ownerType: ownerType,
        ownerId: ownerId,
        category: category,
        mimeType: mimeType,
        sizeBytes: bytes.length,
        originalFileName: fileName,
      );

      await _uploadBinary(
        uploadUrl: ticket.uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      );

      return await _confirmUploadWithRetry(id: ticket.id);
    } on ApiException {
      if (ticket != null) {
        await _abortUpload(
          id: ticket.id,
          reason: 'Client upload failed before confirmation.',
        );
      }
      rethrow;
    } catch (error) {
      if (ticket != null) {
        await _abortUpload(
          id: ticket.id,
          reason: 'Client upload failed before confirmation.',
        );
      }
      throw ApiException(message: 'No se pudo subir el adjunto.');
    }
  }

  Future<String> getDownloadUrl({
    required int attachmentId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/files/$attachmentId/download-url');

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      final url = body['downloadUrl']?.toString() ?? '';
      if (url.isEmpty) {
        throw ApiException(message: 'No se pudo obtener la URL de descarga.');
      }

      return url;
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo obtener la URL de descarga.');
    }
  }

  Future<AttachmentItem> _confirmUpload({
    required int id,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/files/confirm',
        data: {'id': id},
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      return AttachmentItem.fromMap(body);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo confirmar el adjunto.');
    }
  }

  Future<AttachmentItem> _confirmUploadWithRetry({
    required int id,
  }) async {
    ApiException? lastError;
    for (int attempt = 1; attempt <= 3; attempt += 1) {
      try {
        return await _confirmUpload(id: id);
      } on ApiException catch (error) {
        lastError = error;
        final message = error.message.toLowerCase();
        final isMissingObject = message.contains('object not found in s3') || message.contains('upload must complete');
        if (!isMissingObject || attempt == 3) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
    }

    throw lastError ?? ApiException(message: 'No se pudo confirmar el adjunto.');
  }

  Future<void> _abortUpload({
    required int id,
    required String reason,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/files/$id/abort',
        data: {'reason': reason},
      );
    } catch (_) {
      // Best effort cleanup; ignore errors.
    }
  }

  Future<UploadTicket> _createUploadUrl({
    required String ownerType,
    required int ownerId,
    required String category,
    required String mimeType,
    required int sizeBytes,
    required String originalFileName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/files/upload-url',
        data: {
          'ownerType': ownerType,
          'ownerId': ownerId,
          'category': category,
          'mimeType': mimeType,
          'sizeBytes': sizeBytes,
          'originalFileName': originalFileName,
        },
      );

      final body = _unwrapBody(response.data ?? <String, dynamic>{});
      return UploadTicket.fromMap(body);
    } on DioException catch (error) {
      throw _toApiException(error, 'No se pudo iniciar la subida de adjunto.');
    }
  }

  Future<void> _uploadBinary({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final response = await _uploadDio.put<List<int>>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: <String, String>{'Content-Type': mimeType},
          validateStatus: (status) => status != null,
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw _buildStorageUploadException(
          statusCode: response.statusCode,
          responseData: response.data,
          responseHeaders: response.headers,
          sentMimeType: mimeType,
        );
      }
    } on DioException catch (error) {
      throw _buildStorageUploadException(
        statusCode: error.response?.statusCode,
        responseData: error.response?.data,
        responseHeaders: error.response?.headers,
        sentMimeType: mimeType,
      );
    }
  }

  ApiException _buildStorageUploadException({
    required int? statusCode,
    required dynamic responseData,
    required Headers? responseHeaders,
    required String sentMimeType,
  }) {
    final rawBody = _decodeResponseBody(responseData);
    final storageCode = _xmlField(rawBody, 'Code');
    final storageMessage = _xmlField(rawBody, 'Message');
    final requestId = _xmlField(rawBody, 'RequestId');
    final hostId = _xmlField(rawBody, 'HostId');
    final responseContentType = responseHeaders?.value('content-type');

    final summary = [
      if (storageCode != null && storageCode.isNotEmpty) storageCode,
      if (storageMessage != null && storageMessage.isNotEmpty) storageMessage,
    ].join(': ');

    final message = summary.isEmpty
        ? 'No se pudo subir el archivo al almacenamiento (HTTP ${statusCode ?? '-'}).'
        : 'No se pudo subir el archivo al almacenamiento (HTTP ${statusCode ?? '-'}). $summary';

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: storageCode,
      details: {
        'statusCode': statusCode,
        'storageCode': storageCode,
        'storageMessage': storageMessage,
        'requestId': requestId,
        'hostId': hostId,
        'sentMimeType': sentMimeType,
        'responseContentType': responseContentType,
        'responseSnippet': rawBody.length > 1000 ? rawBody.substring(0, 1000) : rawBody,
      },
    );
  }

  String _decodeResponseBody(dynamic data) {
    if (data == null) return '';

    if (data is List<int>) {
      return utf8.decode(data, allowMalformed: true).trim();
    }

    if (data is Uint8List) {
      return utf8.decode(data, allowMalformed: true).trim();
    }

    if (data is String) {
      return data.trim();
    }

    return data.toString().trim();
  }

  String? _xmlField(String xml, String field) {
    if (xml.isEmpty) return null;
    final regex = RegExp('<$field>([\\s\\S]*?)</$field>', caseSensitive: false);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim();
  }

  Map<String, dynamic> _unwrapBody(Map<String, dynamic> body) {
    final success = body['success'];
    if (success is bool) {
      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        body,
        (raw) => (raw as Map).cast<String, dynamic>(),
      );

      if (!envelope.success || envelope.data == null) {
        throw ApiException(
          message: envelope.message ?? 'No se pudo completar la operacion de archivos.',
          code: envelope.error,
          details: envelope.details,
        );
      }

      return envelope.data!;
    }

    return body;
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
