import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permission_service.dart';
import '../../files/data/files_api.dart';
import '../../files/presentation/customer_attachments_screen.dart';
import '../data/customer_model.dart';
import '../data/customers_api.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({
    super.key,
    required this.customersApi,
    required this.filesApi,
    required this.permissionService,
    required this.canCreateCustomer,
    required this.canViewCustomerAttachments,
    required this.allowedUploadCategories,
  });

  final CustomersApi customersApi;
  final FilesApi filesApi;
  final PermissionService permissionService;
  final bool canCreateCustomer;
  final bool canViewCustomerAttachments;
  final Set<String> allowedUploadCategories;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  List<Customer> _items = const <Customer>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = _searchController.text.trim();
      final customers = await widget.customersApi.listCustomers(
        query: query.isEmpty ? null : query,
      );

      if (!mounted) return;
      setState(() {
        _items = customers;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar clientes.';
        _loading = false;
      });
    }
  }

  Future<void> _openCreateModal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateCustomerSheet(customersApi: widget.customersApi),
    );

    if (created == true) {
      await _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadCustomers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: widget.canCreateCustomer
          ? FloatingActionButton.extended(
              onPressed: _openCreateModal,
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo cliente'),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
              colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _CustomersHeroCard(
                totalCustomers: _items.length,
                onRefresh: _loadCustomers,
                onCreateCustomer: widget.canCreateCustomer ? _openCreateModal : null,
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Buscar y filtrar',
                subtitle: 'Encuentra clientes por nombre, telefono o documento.',
              ),
              const SizedBox(height: 10),
              _CustomerSearchCard(
                controller: _searchController,
                onSearch: _loadCustomers,
                onClear: () {
                  _searchController.clear();
                  _loadCustomers();
                },
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Resultados',
                subtitle: 'Toca un cliente para abrir su carpeta de adjuntos.',
              ),
              const SizedBox(height: 10),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _EmptyStateCard(
        icon: Icons.error_outline,
        title: 'No pudimos cargar clientes',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _loadCustomers,
      );
    }

    if (_items.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.people_outline,
        title: 'Aun no hay clientes',
        message: widget.canCreateCustomer
            ? 'Crea el primer cliente para empezar a administrar adjuntos y cartera.'
            : 'No tienes permiso para crear clientes. Solicita acceso customers.create.',
        actionLabel: widget.canCreateCustomer ? 'Nuevo cliente' : 'Recargar',
        onAction: widget.canCreateCustomer ? _openCreateModal : _loadCustomers,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = _items[index];
        return _CustomerCard(
          customer: customer,
          canOpenAttachments: widget.canViewCustomerAttachments,
          onTap: widget.canViewCustomerAttachments
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomerAttachmentsScreen(
                        customer: customer,
                        filesApi: widget.filesApi,
                        permissionService: widget.permissionService,
                        canViewAttachments: widget.canViewCustomerAttachments,
                        allowedUploadCategories: widget.allowedUploadCategories,
                      ),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No tienes permiso files.profile.view.')),
                  );
                },
        );
      },
    );
  }
}

class _CustomersHeroCard extends StatelessWidget {
  const _CustomersHeroCard({
    required this.totalCustomers,
    required this.onRefresh,
    required this.onCreateCustomer,
  });

  final int totalCustomers;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateCustomer;

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
                      'Clientes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestiona tu cartera con una vista clara de altas, documentos y adjuntos.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.people_alt_outlined, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStatPill(label: 'Registrados', value: '$totalCustomers'),
              const _MiniStatPill(label: 'Adjuntos', value: 'Perfil / ID'),
              _MiniStatPill(label: 'Accion', value: onCreateCustomer != null ? 'Nuevo cliente' : 'Solo consulta'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreateCustomer,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(onCreateCustomer != null ? 'Nuevo cliente' : 'Sin permiso'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerSearchCard extends StatelessWidget {
  const _CustomerSearchCard({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

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
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre, telefono o documento',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onSearch,
                  child: const Text('Buscar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.canOpenAttachments,
    required this.onTap,
  });

  final Customer customer;
  final bool canOpenAttachments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _initials(customer.fullName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2ECE7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                initials,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tel: ${customer.phone ?? '-'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Doc: ${customer.documentNumber ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(customer.status),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 8),
                Icon(
                  canOpenAttachments ? Icons.chevron_right : Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
    if (parts.isEmpty) {
      return 'C';
    }
    return parts.map((part) => part[0]).join().toUpperCase();
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CreateCustomerSheet extends StatefulWidget {
  const _CreateCustomerSheet({required this.customersApi});

  final CustomersApi customersApi;

  @override
  State<_CreateCustomerSheet> createState() => _CreateCustomerSheetState();
}

class _CreateCustomerSheetState extends State<_CreateCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _documentNumber = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _documentNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.customersApi.createCustomer(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        documentType: _documentNumber.text.trim().isEmpty ? null : 'DUI',
        documentNumber: _documentNumber.text.trim().isEmpty ? null : _documentNumber.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _submitting = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el cliente.')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nombre',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Apellido',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Telefono',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _documentNumber,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Documento',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Guardando...' : 'Guardar cliente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
