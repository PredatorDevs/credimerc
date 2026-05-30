import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/session/session_controller.dart';
import 'core/session/session_store.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/companies/data/companies_api.dart';
import 'features/customers/data/customers_api.dart';
import 'features/loans/data/loans_api.dart';
import 'features/payments/data/payments_api.dart';

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
  final loansApi = LoansApi(dio: apiClient.dio);
  final paymentsApi = PaymentsApi(dio: apiClient.dio);
  final sessionController = SessionController(
    authApi: authApi,
    companiesApi: companiesApi,
  );

  runApp(
    CrediMercApp(
      apiClient: apiClient,
      sessionController: sessionController,
      customersApi: customersApi,
      loansApi: loansApi,
      paymentsApi: paymentsApi,
    ),
  );
}

class CrediMercApp extends StatelessWidget {
  const CrediMercApp({
    super.key,
    required this.apiClient,
    required this.sessionController,
    required this.customersApi,
    required this.loansApi,
    required this.paymentsApi,
  });

  final ApiClient apiClient;
  final SessionController sessionController;
  final CustomersApi customersApi;
  final LoansApi loansApi;
  final PaymentsApi paymentsApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrediMerc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
      ),
      home: _BootstrapGate(
        sessionController: sessionController,
        customersApi: customersApi,
        loansApi: loansApi,
        paymentsApi: paymentsApi,
      ),
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate({
    required this.sessionController,
    required this.customersApi,
    required this.loansApi,
    required this.paymentsApi,
  });

  final SessionController sessionController;
  final CustomersApi customersApi;
  final LoansApi loansApi;
  final PaymentsApi paymentsApi;

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
              return HomeScreen(
                sessionController: widget.sessionController,
                customersApi: widget.customersApi,
                loansApi: widget.loansApi,
                paymentsApi: widget.paymentsApi,
              );
            }

            return LoginScreen(sessionController: widget.sessionController);
          },
        );
      },
    );
  }
}
