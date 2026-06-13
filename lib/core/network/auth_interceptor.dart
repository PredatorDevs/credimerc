import 'dart:async';

import 'package:dio/dio.dart';

import '../session/auth_session.dart';
import '../session/session_store.dart';
import '../../features/auth/data/auth_remote_data_source.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SessionStore sessionStore,
    required AuthRemoteDataSource authRemoteDataSource,
  })  : _sessionStore = sessionStore,
        _authRemoteDataSource = authRemoteDataSource;

  final SessionStore _sessionStore;
  final AuthRemoteDataSource _authRemoteDataSource;

  AuthSession? _cachedSession;
  Future<AuthSession?>? _refreshing;

  static const _kSkipAuth = 'skipAuth';
  static const _kRetried = 'authRetried';

  Future<AuthSession?> _loadSession() async {
    _cachedSession = await _sessionStore.read();
    return _cachedSession;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra[_kSkipAuth] == true;
    if (skipAuth) {
      return handler.next(options);
    }

    final session = await _loadSession();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final responseStatus = err.response?.statusCode;
    final request = err.requestOptions;

    if (responseStatus != 401 || request.extra[_kSkipAuth] == true) {
      return handler.next(err);
    }

    final alreadyRetried = request.extra[_kRetried] == true;
    if (alreadyRetried) {
      await _sessionStore.clear();
      _cachedSession = null;
      return handler.next(err);
    }

    try {
      final session = await _refreshSession();
      if (session == null) {
        await _sessionStore.clear();
        _cachedSession = null;
        return handler.next(err);
      }

      request.extra[_kRetried] = true;
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';

      final retryResponse = await _retryRequest(err, request);
      return handler.resolve(retryResponse);
    } catch (_) {
      await _sessionStore.clear();
      _cachedSession = null;
      return handler.next(err);
    }
  }

  Future<AuthSession?> _refreshSession() {
    final ongoing = _refreshing;
    if (ongoing != null) {
      return ongoing;
    }

    final future = _doRefresh();
    _refreshing = future;

    return future.whenComplete(() => _refreshing = null);
  }

  Future<AuthSession?> _doRefresh() async {
    final current = await _loadSession();
    if (current == null) {
      return null;
    }

    final newTokens = await _authRemoteDataSource.refreshToken(current.refreshToken);
    final updated = newTokens.toSession();

    await _sessionStore.write(updated);
    _cachedSession = updated;
    return updated;
  }

  Future<Response<dynamic>> _retryRequest(
    DioException original,
    RequestOptions request,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: request.baseUrl,
        connectTimeout: request.connectTimeout,
        receiveTimeout: request.receiveTimeout,
        sendTimeout: request.sendTimeout,
        responseType: request.responseType,
        contentType: request.contentType,
      ),
    );

    return dio.request<dynamic>(
      request.path,
      data: request.data,
      queryParameters: request.queryParameters,
      options: Options(
        method: request.method,
        headers: request.headers,
        responseType: request.responseType,
        contentType: request.contentType,
        extra: request.extra,
      ),
      cancelToken: request.cancelToken,
      onReceiveProgress: request.onReceiveProgress,
      onSendProgress: request.onSendProgress,
    );
  }
}
