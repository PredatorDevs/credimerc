import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../customers/data/customer_model.dart';
import '../../payments/data/payments_api.dart';
import '../../payments/presentation/loan_payments_screen.dart';
import '../data/loan_model.dart';
import '../data/loans_api.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({
    super.key,
    required this.loansApi,
    required this.paymentsApi,
    required this.canCreateLoan,
    required this.canCreatePayment,
    required this.canVoidPayment,
  });

  final LoansApi loansApi;
  final PaymentsApi paymentsApi;
  final bool canCreateLoan;
  final bool canCreatePayment;
  final bool canVoidPayment;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _items = const <Loan>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loans = await widget.loansApi.listLoans();
      if (!mounted) return;

      setState(() {
        _items = loans;
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
        _error = 'No fue posible cargar prestamos.';
        _loading = false;
      });
    }
  }

  Future<void> _openCreateModal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateLoanSheet(loansApi: widget.loansApi),
    );

    if (created == true) {
      await _loadLoans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: widget.canCreateLoan
          ? FloatingActionButton.extended(
              onPressed: _openCreateModal,
              icon: const Icon(Icons.add_card),
              label: const Text('Nuevo prestamo'),
            )
          : null,
      appBar: AppBar(
        title: const Text('Prestamos'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadLoans,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
              _LoansHeroCard(
                loanCount: _items.length,
                totalBalance: _items.fold<double>(0, (sum, item) => sum + item.balanceAmount),
                overdueCount: _items.where((item) => item.status == 'OVERDUE').length,
                onRefresh: _loadLoans,
                onCreateLoan: widget.canCreateLoan ? _openCreateModal : null,
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Cartera',
                subtitle: 'Seguimiento operativo de préstamos y su saldo vigente.',
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
        title: 'No pudimos cargar prestamos',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _loadLoans,
      );
    }

    if (_items.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Aun no hay prestamos',
        message: widget.canCreateLoan
            ? 'Crea el primer préstamo para iniciar la cartera y registrar pagos.'
            : 'No tienes permiso para crear prestamos. Solicita acceso loans.create.',
        actionLabel: widget.canCreateLoan ? 'Nuevo prestamo' : 'Recargar',
        onAction: widget.canCreateLoan ? _openCreateModal : _loadLoans,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = _items[index];
        return _LoanCard(
          loan: loan,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LoanPaymentsScreen(
                  loan: loan,
                  paymentsApi: widget.paymentsApi,
                  canCreatePayment: widget.canCreatePayment,
                  canVoidPayment: widget.canVoidPayment,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoansHeroCard extends StatelessWidget {
  const _LoansHeroCard({
    required this.loanCount,
    required this.totalBalance,
    required this.overdueCount,
    required this.onRefresh,
    required this.onCreateLoan,
  });

  final int loanCount;
  final double totalBalance;
  final int overdueCount;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateLoan;

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
                      'Cartera',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Visualiza el pulso de tu negocio: volumen, saldo y mora al instante.',
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
                  color: colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.account_balance_wallet_outlined, color: colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStatPill(label: 'Prestamos', value: '$loanCount'),
              _MiniStatPill(label: 'Saldo total', value: totalBalance.toStringAsFixed(2)),
              _MiniStatPill(label: 'En mora', value: '$overdueCount'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreateLoan,
                  icon: const Icon(Icons.add_card),
                  label: Text(onCreateLoan != null ? 'Nuevo prestamo' : 'Sin permiso'),
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

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.onTap,
  });

  final Loan loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = switch (loan.status) {
      'PAID' => const Color(0xFF0E9F7A),
      'OVERDUE' => const Color(0xFFB42318),
      'CANCELLED' => const Color(0xFF7A7A7A),
      _ => colorScheme.primary,
    };

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.payments_outlined, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loan.loanNumber} · ${loan.customerName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicio: ${loan.startDate} · Vence: ${loan.dueDate}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(loan.status),
                  backgroundColor: statusColor.withOpacity(0.10),
                  side: BorderSide(color: statusColor.withOpacity(0.20)),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(label: 'Principal', value: loan.principalAmount.toStringAsFixed(2)),
                _MetricPill(label: 'Total', value: loan.totalAmount.toStringAsFixed(2)),
                _MetricPill(label: 'Saldo', value: loan.balanceAmount.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Toca para ver pagos y movimientos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CreateLoanSheet extends StatefulWidget {
  const _CreateLoanSheet({required this.loansApi});

  final LoansApi loansApi;

  @override
  State<_CreateLoanSheet> createState() => _CreateLoanSheetState();
}

class _CreateLoanSheetState extends State<_CreateLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController(text: '100.00');
  final _interestController = TextEditingController(text: '20');

  List<Customer> _customers = const <Customer>[];
  int? _selectedCustomerId;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _loadingCustomers = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);

    try {
      final customers = await widget.loansApi.listActiveCustomersForPicker();
      if (!mounted) return;

      setState(() {
        _customers = customers;
        _selectedCustomerId = customers.isNotEmpty ? customers.first.id : null;
        _loadingCustomers = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar clientes.')),
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_dueDate.isBefore(_startDate)) {
          _dueDate = _startDate;
        }
      } else {
        _dueDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente.')),
      );
      return;
    }

    if (_dueDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de vencimiento no puede ser menor al inicio.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.loansApi.createLoan(
        customerId: _selectedCustomerId!,
        principalAmount: double.parse(_principalController.text.trim()),
        interestRate: double.parse(_interestController.text.trim()),
        startDate: _toApiDate(_startDate),
        dueDate: _toApiDate(_dueDate),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el prestamo.')),
      );
    }
  }

  String _toApiDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo prestamo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_loadingCustomers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  items: _customers
                      .map(
                        (customer) => DropdownMenuItem<int>(
                          value: customer.id,
                          child: Text(customer.fullName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _customers.isEmpty
                      ? null
                      : (value) => setState(() => _selectedCustomerId = value),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Cliente',
                  ),
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _principalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Monto principal',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto valido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _interestController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Interes (%)',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un interes valido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text('Inicio: ${_toApiDate(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text('Vence: ${_toApiDate(_dueDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Guardando...' : 'Guardar prestamo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
