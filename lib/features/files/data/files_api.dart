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
    try {
      final ticket = await _createUploadUrl(
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

      return await _confirmUpload(id: ticket.id);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'No se pudo subir el adjunto.');
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
    final response = await _uploadDio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: <String, String>{'Content-Type': mimeType},
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      throw ApiException(message: 'No se pudo subir el archivo al almacenamiento.');
    }
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
