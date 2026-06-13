import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/reports_api.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.reportsApi,
  });

  final ReportsApi reportsApi;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  PortfolioReport? _portfolio;
  List<OverdueLoanItem> _overdue = const <OverdueLoanItem>[];
  DailyPaymentsReport? _daily;
  CollectorPaymentsReport? _collector;

  bool _loading = true;
  String? _error;
  int _rangeDays = 7;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final range = _resolveRange(_rangeDays);
      final results = await Future.wait<dynamic>([
        widget.reportsApi.getPortfolio(),
        widget.reportsApi.getOverdueLoans(limit: 50),
        widget.reportsApi.getDailyPayments(from: range.$1, to: range.$2),
        widget.reportsApi.getCollectorPayments(from: range.$1, to: range.$2),
      ]);

      if (!mounted) return;
      setState(() {
        _portfolio = results[0] as PortfolioReport;
        _overdue = results[1] as List<OverdueLoanItem>;
        _daily = results[2] as DailyPaymentsReport;
        _collector = results[3] as CollectorPaymentsReport;
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
        _error = 'No se pudieron cargar los reportes.';
        _loading = false;
      });
    }
  }

  (String, String) _resolveRange(int days) {
    final now = DateTime.now();
    final to = _formatDate(now);
    final from = _formatDate(now.subtract(Duration(days: days - 1)));
    return (from, to);
  }

  String _formatDate(DateTime value) {
    final year = value.year;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _currency(num value) {
    final negative = value < 0;
    final cents = (value.abs() * 100).round();
    final whole = (cents ~/ 100).toString();
    final decimal = (cents % 100).toString().padLeft(2, '0');

    final chunks = <String>[];
    for (int i = whole.length; i > 0; i -= 3) {
      final start = (i - 3).clamp(0, i);
      chunks.insert(0, whole.substring(start, i));
    }

    final grouped = chunks.join(',');
    return '${negative ? '-' : ''}\$$grouped.$decimal';
  }

  Future<void> _copyCsv() async {
    final daily = _daily;
    final collector = _collector;
    if (daily == null || collector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aun no hay datos para exportar.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('daily_payments');
    buffer.writeln('day,payments_count,total_amount');
    for (final item in daily.items) {
      buffer.writeln('${item.day},${item.paymentsCount},${item.totalAmount.toStringAsFixed(2)}');
    }

    buffer.writeln('');
    buffer.writeln('collector_payments');
    buffer.writeln('collector,payments_count,total_amount');
    for (final item in collector.items) {
      final safeName = item.collectorName.replaceAll(',', ' ');
      buffer.writeln('$safeName,${item.paymentsCount},${item.totalAmount.toStringAsFixed(2)}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copiado al portapapeles.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporteria MVP'),
        actions: [
          IconButton(
            tooltip: 'Copiar CSV',
            onPressed: _copyCsv,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadReports,
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadReports)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _RangeSelector(
                          selectedDays: _rangeDays,
                          onSelectedDays: (days) {
                            setState(() => _rangeDays = days);
                            _loadReports();
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPortfolioCards(),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Prestamos en mora',
                          subtitle: 'Top de cartera vencida con mayor antiguedad.',
                        ),
                        const SizedBox(height: 10),
                        _OverdueList(items: _overdue, currency: _currency),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Pagos diarios',
                          subtitle: 'Del ${_daily?.from ?? '-'} al ${_daily?.to ?? '-'}',
                        ),
                        const SizedBox(height: 10),
                        _DailyTable(items: _daily?.items ?? const <DailyPaymentItem>[], currency: _currency),
                        const SizedBox(height: 18),
                        _SectionHeader(
                          title: 'Pagos por cobrador',
                          subtitle: 'Ranking por monto recaudado.',
                        ),
                        const SizedBox(height: 10),
                        _CollectorTable(
                          items: _collector?.items ?? const <CollectorPaymentItem>[],
                          currency: _currency,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildPortfolioCards() {
    final data = _portfolio;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(label: 'Total prestado', value: _currency(data.totalPrincipalLoaned)),
        _MetricCard(label: 'Total pendiente', value: _currency(data.totalOutstanding)),
        _MetricCard(label: 'Cobrado hoy', value: _currency(data.totalCollectedToday)),
        _MetricCard(label: 'Prestamos activos', value: '${data.activeLoans}'),
        _MetricCard(label: 'Prestamos vencidos', value: '${data.overdueLoans}'),
        _MetricCard(label: 'Clientes activos', value: '${data.activeCustomers}'),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedDays,
    required this.onSelectedDays,
  });

  final int selectedDays;
  final ValueChanged<int> onSelectedDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('7 dias'),
            selected: selectedDays == 7,
            onSelected: (_) => onSelectedDays(7),
          ),
          ChoiceChip(
            label: const Text('30 dias'),
            selected: selectedDays == 30,
            onSelected: (_) => onSelectedDays(30),
          ),
          ChoiceChip(
            label: const Text('90 dias'),
            selected: selectedDays == 90,
            onSelected: (_) => onSelectedDays(90),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE7)),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _OverdueList extends StatelessWidget {
  const _OverdueList({
    required this.items,
    required this.currency,
  });

  final List<OverdueLoanItem> items;
  final String Function(num value) currency;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SimpleCard(message: 'Sin prestamos vencidos para mostrar.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text('${item.loanNumber} - ${item.customerName}'),
            subtitle: Text('Dias vencido: ${item.daysOverdue}'),
            trailing: Text(currency(item.balanceAmount)),
          );
        },
      ),
    );
  }
}

class _DailyTable extends StatelessWidget {
  const _DailyTable({
    required this.items,
    required this.currency,
  });

  final List<DailyPaymentItem> items;
  final String Function(num value) currency;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SimpleCard(message: 'Sin pagos en el rango seleccionado.');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(item.day)),
                    Text('${item.paymentsCount} pagos'),
                    const SizedBox(width: 12),
                    Text(currency(item.totalAmount)),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CollectorTable extends StatelessWidget {
  const _CollectorTable({
    required this.items,
    required this.currency,
  });

  final List<CollectorPaymentItem> items;
  final String Function(num value) currency;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SimpleCard(message: 'Sin cobradores con pagos en el rango.');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(item.collectorName)),
                    Text('${item.paymentsCount} pagos'),
                    const SizedBox(width: 12),
                    Text(currency(item.totalAmount)),
                  ],
                ),
              ),
            )
            .toList(growable: false),
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

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Text(message),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
