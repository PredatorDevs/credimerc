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
  });

  final LoansApi loansApi;
  final PaymentsApi paymentsApi;

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
    return Scaffold(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        icon: const Icon(Icons.add_card),
        label: const Text('Nuevo prestamo'),
      ),
      body: _buildBody(),
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
      return const Center(child: Text('No hay prestamos registrados.'));
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final loan = _items[index];
        return ListTile(
          title: Text('${loan.loanNumber} - ${loan.customerName}'),
          subtitle: Text(
            'Principal: ${loan.principalAmount.toStringAsFixed(2)} | Saldo: ${loan.balanceAmount.toStringAsFixed(2)}',
          ),
          trailing: Chip(label: Text(loan.status)),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LoanPaymentsScreen(
                  loan: loan,
                  paymentsApi: widget.paymentsApi,
                ),
              ),
            );
          },
        );
      },
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
