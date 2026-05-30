import 'package:flutter/material.dart';

import '../../../core/session/session_controller.dart';
import '../../customers/data/customers_api.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../companies/data/company_membership.dart';
import '../../loans/data/loans_api.dart';
import '../../loans/presentation/loans_screen.dart';
import '../../payments/data/payments_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.sessionController.activeCompanyId;
    widget.sessionController.refreshCompanies();
  }

  Future<void> _applyCompanyChange() async {
    final selected = _selectedCompanyId;
    if (selected == null) {
      return;
    }

    await widget.sessionController.selectCompany(selected);
    if (!mounted) {
      return;
    }

    final error = widget.sessionController.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      widget.sessionController.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Empresa activa actualizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (context, _) {
        final profile = widget.sessionController.profile ?? <String, dynamic>{};
        final user = profile['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final companies = widget.sessionController.companies;
        final activeCompanyId = widget.sessionController.activeCompanyId;

        _selectedCompanyId ??= activeCompanyId;
        final availableCompanyIds = companies.map((c) => c.id).toSet();
        final dropdownValue = availableCompanyIds.contains(_selectedCompanyId)
          ? _selectedCompanyId
          : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('CrediMerc'),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesion',
                onPressed: () => widget.sessionController.logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, ${user['fullName'] ?? 'Usuario'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Email: ${user['email'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('Estado: ${user['status'] ?? '-'}'),
                const SizedBox(height: 20),
                Text(
                  'Empresa activa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: dropdownValue,
                  items: companies
                      .map(
                        (CompanyMembership company) => DropdownMenuItem<int>(
                          value: company.id,
                          child: Text('${company.name} (#${company.id})'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: companies.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCompanyId = value;
                          });
                        },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: companies.isEmpty ? null : _applyCompanyChange,
                      child: const Text('Cambiar empresa'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.sessionController.refreshCompanies,
                      child: const Text('Recargar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Empresa activa actual: ${activeCompanyId ?? '-'}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CustomersScreen(customersApi: widget.customersApi),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Ir a clientes'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LoansScreen(
                          loansApi: widget.loansApi,
                          paymentsApi: widget.paymentsApi,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Ir a prestamos'),
                ),
                const SizedBox(height: 10),
                const Text('Base de integracion lista para conectar modulos de negocio.'),
              ],
            ),
          ),
        );
      },
    );
  }
}
