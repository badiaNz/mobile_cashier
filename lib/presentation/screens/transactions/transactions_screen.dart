import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../../data/models/transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final filters = {
      'date_from': DateTime(_from.year, _from.month, _from.day).toIso8601String(),
      'date_to': DateTime(_to.year, _to.month, _to.day, 23, 59, 59).toIso8601String(),
    };
    final transactions = ref.watch(transactionsProvider(filters));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM').format(_from)} - ${DateFormat('dd MMM yyyy').format(_to)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                transactions.when(
                  data: (list) => Text('${list.length} transaksi', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 60, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Belum ada transaksi', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return GestureDetector(
                      onTap: () => context.go('/transactions/${t.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _statusColor(t.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_paymentIcon(t.paymentMethod), color: _statusColor(t.status), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(t.invoiceNumber, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(formatter.format(t.total), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(dateFormatter.format(t.createdAt), style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                                      _StatusBadge(t.status),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(t.cashierName ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 30).ms),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return AppColors.success;
      case TransactionStatus.cancelled: return AppColors.error;
      case TransactionStatus.refunded: return AppColors.warning;
      case TransactionStatus.pending: return AppColors.info;
    }
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.payments_rounded;
      case PaymentMethod.transfer: return Icons.account_balance_rounded;
      case PaymentMethod.qris: return Icons.qr_code_rounded;
      case PaymentMethod.card: return Icons.credit_card_rounded;
      case PaymentMethod.other: return Icons.swap_horiz_rounded;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      TransactionStatus.completed => (AppColors.success, 'Selesai'),
      TransactionStatus.cancelled => (AppColors.error, 'Dibatalkan'),
      TransactionStatus.refunded => (AppColors.warning, 'Refund'),
      TransactionStatus.pending => (AppColors.info, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}


