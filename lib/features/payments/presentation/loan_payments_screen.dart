import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../loans/data/loan_model.dart';
import '../data/payment_model.dart';
import '../data/payments_api.dart';

class LoanPaymentsScreen extends StatefulWidget {
  const LoanPaymentsScreen({
    super.key,
    required this.loan,
    required this.paymentsApi,
  });

  final Loan loan;
  final PaymentsApi paymentsApi;

  @override
  State<LoanPaymentsScreen> createState() => _LoanPaymentsScreenState();
}

class _LoanPaymentsScreenState extends State<LoanPaymentsScreen> {
  final _searchController = TextEditingController();
  List<Payment> _items = const <Payment>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payments = await widget.paymentsApi.listLoanPayments(widget.loan.id);
      if (!mounted) return;

      setState(() {
        _items = payments;
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
        _error = 'No fue posible cargar pagos.';
        _loading = false;
      });
    }
  }

  Future<void> _openCreatePaymentSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreatePaymentSheet(
        loanId: widget.loan.id,
        paymentsApi: widget.paymentsApi,
      ),
    );

    if (created == true) {
      await _loadPayments();
    }
  }

  Future<void> _voidPayment(Payment payment) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pago #${payment.id} por ${payment.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Motivo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Anular'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.length < 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un motivo de al menos 5 caracteres.')),
      );
      return;
    }

    try {
      await widget.paymentsApi.voidPayment(
        paymentId: payment.id,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago anulado.')),
      );
      await _loadPayments();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo anular el pago.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos ${widget.loan.loanNumber}'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePaymentSheet,
        icon: const Icon(Icons.attach_money),
        label: const Text('Registrar pago'),
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
              _LoanHeroCard(
                loan: widget.loan,
                paymentCount: _items.length,
                onRefresh: _loadPayments,
                onCreatePayment: _openCreatePaymentSheet,
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Buscar y filtrar',
                subtitle: 'Encuentra pagos por referencia, metodo o monto.',
              ),
              const SizedBox(height: 10),
              _SearchCard(
                controller: _searchController,
                onSearch: _loadPayments,
                onClear: () {
                  _searchController.clear();
                  _loadPayments();
                },
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Historial',
                subtitle: 'Cada tarjeta resume el estado, monto y observaciones del pago.',
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
        title: 'No pudimos cargar los pagos',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _loadPayments,
      );
    }

    if (_items.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.payments_outlined,
        title: 'Aun no hay pagos registrados',
        message: 'Registra el primer pago para comenzar a ver el movimiento de este prestamo.',
        actionLabel: 'Registrar pago',
        onAction: _openCreatePaymentSheet,
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = _items[index];
        final isVoided = payment.status == 'VOIDED';

        return _PaymentCard(
          payment: payment,
          isVoided: isVoided,
          onVoid: () => _voidPayment(payment),
        );
      },
    );
  }
}

class _LoanHeroCard extends StatelessWidget {
  const _LoanHeroCard({
    required this.loan,
    required this.paymentCount,
    required this.onRefresh,
    required this.onCreatePayment,
  });

  final Loan loan;
  final int paymentCount;
  final VoidCallback onRefresh;
  final VoidCallback onCreatePayment;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagos del prestamo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${loan.loanNumber} · ${loan.customerName}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                child: Icon(Icons.payments_outlined, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStatPill(label: 'Pagos', value: '$paymentCount'),
              _MiniStatPill(label: 'Principal', value: loan.principalAmount.toStringAsFixed(2)),
              _MiniStatPill(label: 'Saldo', value: loan.balanceAmount.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onCreatePayment,
                icon: const Icon(Icons.attach_money),
                label: const Text('Registrar pago'),
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Estado',
                  value: loan.status,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoPill(
                  label: 'Cliente',
                  value: loan.customerName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
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
              labelText: 'Buscar por referencia, metodo o nota',
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

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.isVoided,
    required this.onVoid,
  });

  final Payment payment;
  final bool isVoided;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isVoided ? const Color(0xFFFDECEC) : colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isVoided ? Icons.block : Icons.payments_outlined,
                  color: isVoided ? const Color(0xFFC24141) : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pago #${payment.id}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        _StatusChip(isVoided: isVoided),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      payment.amount.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(label: 'Metodo', value: payment.paymentMethod),
              _MetaPill(label: 'Fecha', value: payment.paymentDate),
              if (payment.referenceNumber != null && payment.referenceNumber!.trim().isNotEmpty)
                _MetaPill(label: 'Referencia', value: payment.referenceNumber!),
            ],
          ),
          if (payment.voidReason != null && payment.voidReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Motivo: ${payment.voidReason}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8A3B3B),
                      height: 1.35,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: isVoided
                ? const Chip(label: Text('Anulado'))
                : FilledButton.tonalIcon(
                    onPressed: onVoid,
                    icon: const Icon(Icons.block),
                    label: const Text('Anular'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isVoided});

  final bool isVoided;

  @override
  Widget build(BuildContext context) {
    if (isVoided) {
      return Chip(
        label: const Text('VOIDED'),
        backgroundColor: const Color(0xFFFDECEC),
        labelStyle: const TextStyle(color: Color(0xFFC24141), fontWeight: FontWeight.w700),
      );
    }

    return Chip(
      label: const Text('ACTIVO'),
      backgroundColor: const Color(0xFFEAF5EE),
      labelStyle: const TextStyle(color: Color(0xFF1F7A4D), fontWeight: FontWeight.w700),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CreatePaymentSheet extends StatefulWidget {
  const _CreatePaymentSheet({
    required this.loanId,
    required this.paymentsApi,
  });

  final int loanId;
  final PaymentsApi paymentsApi;

  @override
  State<_CreatePaymentSheet> createState() => _CreatePaymentSheetState();
}

class _CreatePaymentSheetState extends State<_CreatePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.paymentsApi.createLoanPayment(
        loanId: widget.loanId,
        amount: double.parse(_amountController.text.trim()),
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pago: $error')),
      );
    }
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
                'Registrar pago',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Monto',
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
                controller: _referenceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Referencia (opcional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Notas (opcional)',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Guardando...' : 'Guardar pago'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
