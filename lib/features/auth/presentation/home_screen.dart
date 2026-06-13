import 'package:flutter/material.dart';

import '../../admin/data/company_users_api.dart';
import '../../admin/data/rbac_api.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/session/session_controller.dart';
import '../../customers/data/customers_api.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../companies/data/company_membership.dart';
import '../../files/data/files_api.dart';
import '../../loans/data/loans_api.dart';
import '../../loans/presentation/loans_screen.dart';
import '../../payments/data/payments_api.dart';
import '../../reports/data/reports_api.dart';
import '../../reports/presentation/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
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

  Future<void> _validatePermissions() async {
    final result = await widget.permissionService.requestMediaPermissions();
    if (!mounted) {
      return;
    }

    switch (result) {
      case MediaPermissionResult.granted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos de camara/fotos concedidos.')),
        );
      case MediaPermissionResult.denied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos denegados. Puedes volver a intentarlo.')),
        );
      case MediaPermissionResult.permanentlyDenied:
        final opened = await widget.permissionService.openSettings();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? 'Permisos bloqueados. Revisa Configuracion de la app.'
                  : 'No se pudo abrir Configuracion automaticamente.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (context, _) {
        final profile = widget.sessionController.profile ?? <String, dynamic>{};
        final user = profile['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final permissions = (profile['permissions'] as List?)
            ?.map((item) => item.toString())
            .toSet() ??
          <String>{};
        final canViewCustomers = permissions.contains('customers.view');
        final canCreateCustomer = permissions.contains('customers.create');
        final canViewLoans = permissions.contains('loans.view');
        final canCreateLoan = permissions.contains('loans.create');
        final canViewPayments = permissions.contains('payments.view');
        final canCreatePayment = permissions.contains('payments.create');
        final canVoidPayment = permissions.contains('payments.void');
        final canManageRoles = permissions.contains('roles.manage');
        final canViewReports = permissions.contains('reports.view');
        final canViewCustomerAttachments = permissions.contains('files.profile.view');
        final allowedUploadCategories = <String>{
          if (permissions.contains('files.profile.upload')) 'PROFILE_PHOTO',
          if (permissions.contains('files.id.upload')) ...<String>['ID_FRONT', 'ID_BACK', 'SELFIE_VERIFICATION'],
          if (permissions.contains('files.supporting.upload')) 'SUPPORTING_DOCUMENT',
        };
        final companies = widget.sessionController.companies;
        final activeCompanyId = widget.sessionController.activeCompanyId;
        final fullName = user['fullName']?.toString().trim().isNotEmpty == true
            ? user['fullName'].toString()
            : 'Usuario';
        final email = user['email']?.toString().trim().isNotEmpty == true
            ? user['email'].toString()
            : '-';
        final userStatus = user['status']?.toString().trim().isNotEmpty == true
            ? user['status'].toString()
            : '-';

        _selectedCompanyId ??= activeCompanyId;
        final availableCompanyIds = companies.map((c) => c.id).toSet();
        final dropdownValue = availableCompanyIds.contains(_selectedCompanyId)
          ? _selectedCompanyId
          : null;
        final activeCompany = companies.where((c) => c.id == activeCompanyId).cast<CompanyMembership?>().firstOrNull;
        final selectedCompany = companies.where((c) => c.id == dropdownValue).cast<CompanyMembership?>().firstOrNull;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Image.asset('lib/assets/credimerclogo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                const Text('CrediMerc'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Validar permisos',
                onPressed: _validatePermissions,
                icon: const Icon(Icons.verified_user_outlined),
              ),
              IconButton(
                tooltip: 'Cerrar sesion',
                onPressed: () => widget.sessionController.logout(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.09),
                  Theme.of(context).scaffoldBackgroundColor,
                  colorScheme.secondary.withOpacity(0.06),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -90,
                    right: -30,
                    child: _HomeGlowBlob(color: colorScheme.secondary.withOpacity(0.14), size: 190),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -70,
                    child: _HomeGlowBlob(color: colorScheme.primary.withOpacity(0.12), size: 240),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _DashboardHeroCard(
                        fullName: fullName,
                        email: email,
                        userStatus: userStatus,
                        activeCompanyName: activeCompany?.name,
                        activeCompanyId: activeCompanyId,
                        selectedCompanyName: selectedCompany?.name,
                        onRefreshCompanies: widget.sessionController.refreshCompanies,
                        onOpenPermissions: _validatePermissions,
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Accesos rapidos',
                        subtitle: 'Entradas directas a las areas que usas con mas frecuencia.',
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.08,
                        children: [
                          _ShortcutCard(
                            icon: Icons.people_alt_outlined,
                            title: 'Clientes',
                            description: 'Alta, busqueda y documentos.',
                            lockedMessage: 'Sin permiso customers.view',
                            enabled: canViewCustomers,
                            onTap: canViewCustomers
                                ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CustomersScreen(
                                    customersApi: widget.customersApi,
                                    filesApi: widget.filesApi,
                                    permissionService: widget.permissionService,
                                    canCreateCustomer: canCreateCustomer,
                                    canViewCustomerAttachments: canViewCustomerAttachments,
                                    allowedUploadCategories: allowedUploadCategories,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                          _ShortcutCard(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Prestamos',
                            description: 'Crea, revisa y administra saldos.',
                            lockedMessage: 'Sin permiso loans.view',
                            enabled: canViewLoans,
                            onTap: canViewLoans
                                ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoansScreen(
                                    loansApi: widget.loansApi,
                                    paymentsApi: widget.paymentsApi,
                                    canCreateLoan: canCreateLoan,
                                    canCreatePayment: canCreatePayment,
                                    canVoidPayment: canVoidPayment,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                          _ShortcutCard(
                            icon: Icons.payments_outlined,
                            title: 'Pagos',
                            description: 'Registra y anula abonos rapido.',
                            lockedMessage: 'Sin permiso payments.view',
                            enabled: canViewPayments,
                            onTap: canViewPayments
                                ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LoansScreen(
                                    loansApi: widget.loansApi,
                                    paymentsApi: widget.paymentsApi,
                                    canCreateLoan: canCreateLoan,
                                    canCreatePayment: canCreatePayment,
                                    canVoidPayment: canVoidPayment,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                          // _ShortcutCard(
                          //   icon: Icons.folder_open_outlined,
                          //   title: 'Adjuntos',
                          //   description: 'Documentos, fotos e identidad.',
                          //   enabled: true,
                          //   onTap: _validatePermissions,
                          //   emphasize: true,
                          // ),
                          _ShortcutCard(
                            icon: Icons.insert_chart_outlined,
                            title: 'Reportes',
                            description: 'KPIs de cartera, mora y cobranza.',
                            lockedMessage: 'Sin permiso reports.view',
                            enabled: canViewReports,
                            onTap: canViewReports
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ReportsScreen(reportsApi: widget.reportsApi),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                          _ShortcutCard(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Administracion',
                            description: 'Usuarios, roles y permisos del tenant.',
                            lockedMessage: 'Sin permiso roles.manage',
                            enabled: canManageRoles,
                            onTap: canManageRoles
                                ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AdminScreen(
                                    companyUsersApi: widget.companyUsersApi,
                                    rbacApi: widget.rbacApi,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Empresa activa',
                        subtitle: 'Selecciona el contexto operativo antes de gestionar cartera.',
                      ),
                      const SizedBox(height: 10),
                      _CompanySwitchCard(
                        companies: companies,
                        dropdownValue: dropdownValue,
                        selectedCompanyId: _selectedCompanyId,
                        onSelectedCompanyChanged: (value) {
                          setState(() {
                            _selectedCompanyId = value;
                          });
                        },
                        onApply: companies.isEmpty ? null : _applyCompanyChange,
                        onRefresh: widget.sessionController.refreshCompanies,
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({
    required this.fullName,
    required this.email,
    required this.userStatus,
    required this.activeCompanyName,
    required this.activeCompanyId,
    required this.selectedCompanyName,
    required this.onRefreshCompanies,
    required this.onOpenPermissions,
  });

  final String fullName;
  final String email;
  final String userStatus;
  final String? activeCompanyName;
  final int? activeCompanyId;
  final String? selectedCompanyName;
  final VoidCallback onRefreshCompanies;
  final VoidCallback onOpenPermissions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2ECE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, $fullName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset('lib/assets/credimerclogo.png', fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.verified_user_outlined,
                label: 'Estado: $userStatus',
              ),
              _InfoPill(
                icon: Icons.apartment_outlined,
                label: activeCompanyName != null
                    ? 'Activa: $activeCompanyName (#${activeCompanyId ?? '-'})'
                    : 'Sin empresa activa',
              ),
              if (selectedCompanyName != null)
                _InfoPill(
                  icon: Icons.swap_horiz,
                  label: 'Seleccionada: $selectedCompanyName',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRefreshCompanies,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar empresas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenPermissions,
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Permisos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.enabled,
    this.lockedMessage,
    this.emphasize = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool enabled;
  final String? lockedMessage;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withOpacity(emphasize ? 0.92 : 0.84)
              : Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: emphasize ? colorScheme.secondary.withOpacity(0.28) : const Color(0xFFE2ECE7),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: emphasize ? colorScheme.secondary.withOpacity(0.18) : colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                enabled ? icon : Icons.lock_outline,
                color: colorScheme.onSurface,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              enabled ? description : (lockedMessage ?? 'Sin permiso para esta accion.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanySwitchCard extends StatelessWidget {
  const _CompanySwitchCard({
    required this.companies,
    required this.dropdownValue,
    required this.selectedCompanyId,
    required this.onSelectedCompanyChanged,
    required this.onApply,
    required this.onRefresh,
  });

  final List<CompanyMembership> companies;
  final int? dropdownValue;
  final int? selectedCompanyId;
  final ValueChanged<int?> onSelectedCompanyChanged;
  final Future<void> Function()? onApply;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2ECE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            onChanged: companies.isEmpty ? null : onSelectedCompanyChanged,
            decoration: const InputDecoration(
              labelText: 'Empresa activa',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: companies.isEmpty ? null : onApply,
                  child: const Text('Cambiar empresa'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRefresh,
                  child: const Text('Recargar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            selectedCompanyId != null
                ? 'Contexto seleccionado: #$selectedCompanyId'
                : 'Selecciona una empresa para trabajar con su cartera.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HomeGlowBlob extends StatelessWidget {
  const _HomeGlowBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
