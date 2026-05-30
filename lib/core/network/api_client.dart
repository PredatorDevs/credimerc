import 'package:dio/dio.dart';

import '../../features/auth/data/auth_remote_data_source.dart';
import '../session/session_store.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required SessionStore sessionStore,
  })  : _sessionStore = sessionStore,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    final authDataSource = AuthRemoteDataSource(_dio);

    _dio.interceptors.add(
      AuthInterceptor(
        sessionStore: _sessionStore,
        authRemoteDataSource: authDataSource,
      ),
    );
  }

  final SessionStore _sessionStore;
  final Dio _dio;

  Dio get dio => _dio;

  SessionStore get sessionStore => _sessionStore;
}
