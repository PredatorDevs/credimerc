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
  List<Payment> _items = const <Payment>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LoanHeader(loan: widget.loan),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(child: Text('No hay pagos registrados para este prestamo.'));
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final payment = _items[index];
        final isVoided = payment.status == 'VOIDED';

        return ListTile(
          title: Text('Pago #${payment.id} - ${payment.amount.toStringAsFixed(2)}'),
          subtitle: Text(
            'Metodo: ${payment.paymentMethod} | Fecha: ${payment.paymentDate}${payment.voidReason != null ? '\nMotivo: ${payment.voidReason}' : ''}',
          ),
          isThreeLine: payment.voidReason != null,
          trailing: isVoided
              ? const Chip(label: Text('VOIDED'))
              : FilledButton.tonal(
                  onPressed: () => _voidPayment(payment),
                  child: const Text('Anular'),
                ),
        );
      },
    );
  }
}

class _LoanHeader extends StatelessWidget {
  const _LoanHeader({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${loan.loanNumber} - ${loan.customerName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('Principal: ${loan.principalAmount.toStringAsFixed(2)}'),
          Text('Saldo: ${loan.balanceAmount.toStringAsFixed(2)}'),
          Text('Estado: ${loan.status}'),
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago.')),
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
