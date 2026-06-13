import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/permissions/permission_service.dart';
import 'core/session/session_controller.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/company_users_api.dart';
import 'features/admin/data/rbac_api.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/companies/data/companies_api.dart';
import 'features/companies/presentation/company_onboarding_screen.dart';
import 'features/customers/data/customers_api.dart';
import 'features/files/data/files_api.dart';
import 'features/loans/data/loans_api.dart';
import 'features/payments/data/payments_api.dart';
import 'features/reports/data/reports_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStore = SessionStore();
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    sessionStore: sessionStore,
  );
  final authApi = AuthApi(
    dio: apiClient.dio,
    sessionStore: sessionStore,
  );
  final companiesApi = CompaniesApi(dio: apiClient.dio);
  final customersApi = CustomersApi(dio: apiClient.dio);
  final companyUsersApi = CompanyUsersApi(dio: apiClient.dio);
  final rbacApi = RbacApi(dio: apiClient.dio);
  final filesApi = FilesApi(dio: apiClient.dio);
  final loansApi = LoansApi(dio: apiClient.dio);
  final paymentsApi = PaymentsApi(dio: apiClient.dio);
  final reportsApi = ReportsApi(dio: apiClient.dio);
  final permissionService = PermissionService();
  final sessionController = SessionController(
    authApi: authApi,
    companiesApi: companiesApi,
  );

  runApp(
    CrediMercApp(
      apiClient: apiClient,
      sessionController: sessionController,
      customersApi: customersApi,
      companyUsersApi: companyUsersApi,
      rbacApi: rbacApi,
      filesApi: filesApi,
      loansApi: loansApi,
      paymentsApi: paymentsApi,
      reportsApi: reportsApi,
      permissionService: permissionService,
    ),
  );
}

class CrediMercApp extends StatelessWidget {
  const CrediMercApp({
    super.key,
    required this.apiClient,
    required this.sessionController,
    required this.customersApi,
    required this.companyUsersApi,
    required this.rbacApi,
    required this.filesApi,
    required this.loansApi,
    required this.paymentsApi,
    required this.reportsApi,
    required this.permissionService,
  });

  final ApiClient apiClient;
  final SessionController sessionController;
  final CustomersApi customersApi;
  final CompanyUsersApi companyUsersApi;
  final RbacApi rbacApi;
  final FilesApi filesApi;
  final LoansApi loansApi;
  final PaymentsApi paymentsApi;
  final ReportsApi reportsApi;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CrediMerc',
      theme: CrediMercTheme.light(),
      home: _BootstrapGate(
        sessionController: sessionController,
        customersApi: customersApi,
        companyUsersApi: companyUsersApi,
        rbacApi: rbacApi,
        filesApi: filesApi,
        loansApi: loansApi,
        paymentsApi: paymentsApi,
        reportsApi: reportsApi,
        permissionService: permissionService,
      ),
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate({
    required this.sessionController,
    required this.customersApi,
    required this.companyUsersApi,
    required this.rbacApi,
    required this.filesApi,
    required this.loansApi,
    required this.paymentsApi,
    required this.reportsApi,
    required this.permissionService,
  });

  final SessionController sessionController;
  final CustomersApi customersApi;
  final CompanyUsersApi companyUsersApi;
  final RbacApi rbacApi;
  final FilesApi filesApi;
  final LoansApi loansApi;
  final PaymentsApi paymentsApi;
  final ReportsApi reportsApi;
  final PermissionService permissionService;

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = widget.sessionController.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AnimatedBuilder(
          animation: widget.sessionController,
          builder: (context, _) {
            if (widget.sessionController.isAuthenticated) {
              if (widget.sessionController.companies.isEmpty) {
                return CompanyOnboardingScreen(
                  sessionController: widget.sessionController,
                );
              }

              return HomeScreen(
                sessionController: widget.sessionController,
                customersApi: widget.customersApi,
                companyUsersApi: widget.companyUsersApi,
                rbacApi: widget.rbacApi,
                filesApi: widget.filesApi,
                loansApi: widget.loansApi,
                paymentsApi: widget.paymentsApi,
                reportsApi: widget.reportsApi,
                permissionService: widget.permissionService,
              );
            }

            return LoginScreen(sessionController: widget.sessionController);
          },
        );
      },
    );
  }
}
