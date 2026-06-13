import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/companies/data/companies_api.dart';
import '../../features/companies/data/company_membership.dart';
import '../network/api_exception.dart';

enum SessionStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class SessionController extends ChangeNotifier {
  SessionController({
    required AuthApi authApi,
    required CompaniesApi companiesApi,
  })  : _authApi = authApi,
        _companiesApi = companiesApi;

  final AuthApi _authApi;
  final CompaniesApi _companiesApi;

  SessionStatus _status = SessionStatus.initial;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  List<CompanyMembership> _companies = const <CompanyMembership>[];
  int? _activeCompanyId;

  SessionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profile => _profile;
  List<CompanyMembership> get companies => _companies;
  int? get activeCompanyId => _activeCompanyId;

  bool get isAuthenticated => _status == SessionStatus.authenticated;
  bool get isLoading => _status == SessionStatus.loading;

  Future<void> bootstrap() async {
    _setStatus(SessionStatus.loading);

    try {
      final me = await _authApi.me();
      _profile = me;
      _activeCompanyId = (me['activeCompanyId'] as num?)?.toInt();
      await _loadCompanies();
      _errorMessage = null;
      _setStatus(SessionStatus.authenticated);
    } catch (_) {
      _profile = null;
      _companies = const <CompanyMembership>[];
      _activeCompanyId = null;
      _errorMessage = null;
      _setStatus(SessionStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setStatus(SessionStatus.loading);

    try {
      await _authApi.login(email: email, password: password);
      final me = await _authApi.me();
      _profile = me;
      _activeCompanyId = (me['activeCompanyId'] as num?)?.toInt();
      await _loadCompanies();
      _errorMessage = null;
      _setStatus(SessionStatus.authenticated);
    } on ApiException catch (error) {
      _profile = null;
      _companies = const <CompanyMembership>[];
      _activeCompanyId = null;
      _errorMessage = error.message;
      _setStatus(SessionStatus.error);
      _setStatus(SessionStatus.unauthenticated);
    } catch (_) {
      _profile = null;
      _companies = const <CompanyMembership>[];
      _activeCompanyId = null;
      _errorMessage = 'No fue posible iniciar sesion.';
      _setStatus(SessionStatus.error);
      _setStatus(SessionStatus.unauthenticated);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      await _authApi.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible crear la cuenta.';
    }
  }

  Future<void> logout() async {
    _setStatus(SessionStatus.loading);

    try {
      await _authApi.logout();
    } finally {
      _profile = null;
      _companies = const <CompanyMembership>[];
      _activeCompanyId = null;
      _errorMessage = null;
      _setStatus(SessionStatus.unauthenticated);
    }
  }

  Future<void> refreshCompanies() async {
    if (!isAuthenticated) {
      return;
    }

    try {
      await _loadCompanies();
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  Future<void> selectCompany(int companyId) async {
    if (!isAuthenticated) {
      return;
    }

    _setStatus(SessionStatus.loading);

    try {
      await _authApi.selectCompany(companyId);
      final me = await _authApi.me();
      _profile = me;
      _activeCompanyId = (me['activeCompanyId'] as num?)?.toInt();
      await _loadCompanies();
      _errorMessage = null;
      _setStatus(SessionStatus.authenticated);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _setStatus(SessionStatus.error);
      _setStatus(SessionStatus.authenticated);
    } catch (_) {
      _errorMessage = 'No fue posible cambiar de empresa.';
      _setStatus(SessionStatus.error);
      _setStatus(SessionStatus.authenticated);
    }
  }

  Future<String?> createCompanyAndActivate({
    required String name,
    String? commercialName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final companyId = await _companiesApi.createCompany(
        name: name,
        commercialName: commercialName,
        phone: phone,
        email: email,
        address: address,
      );

      await selectCompany(companyId);
      return _errorMessage;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible crear la empresa.';
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    try {
      await _authApi.forgotPassword(email: email);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible solicitar recuperacion de contrasena.';
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authApi.resetPassword(token: token, newPassword: newPassword);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible restablecer la contrasena.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setStatus(SessionStatus next) {
    _status = next;
    notifyListeners();
  }

  Future<void> _loadCompanies() async {
    _companies = await _companiesApi.listMyCompanies();

    if (_activeCompanyId == null && _companies.isNotEmpty) {
      _activeCompanyId = _companies.first.id;
    }
  }
}
