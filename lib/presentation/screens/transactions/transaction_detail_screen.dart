import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../core/database_helper.dart';
import '../../../data/models/transaction_model.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(_transactionDetailProvider(transactionId));
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(icon: const Icon(Icons.print_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: transactionAsync.when(
        data: (data) {
          if (data == null) return const Center(child: Text('Transaksi tidak ditemukan'));
          final (transaction, items) = data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Invoice header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(transaction.invoiceNumber, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(dateFormatter.format(transaction.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(transaction.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info
              _InfoCard(children: [
                _InfoRow('Kasir', transaction.cashierName ?? '-'),
                _InfoRow('Pelanggan', transaction.customerName ?? '-'),
                _InfoRow('Metode Bayar', transaction.paymentMethod.label),
                _InfoRow('Bayar', formatter.format(transaction.amountPaid)),
                if (transaction.changeAmount > 0)
                  _InfoRow('Kembalian', formatter.format(transaction.changeAmount), valueColor: AppColors.success),
              ]),
              const SizedBox(height: 16),

              // Items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item yang Dibeli', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                                Text('${formatter.format(item.productPrice)} × ${item.quantity}', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                                if (item.discountPercentage > 0)
                                  Text('Diskon ${item.discountPercentage.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.success, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text(formatter.format(item.subtotal), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    )),
                    const Divider(color: AppColors.border),
                    _InfoRow('Subtotal', formatter.format(transaction.subtotal)),
                    if (transaction.discountAmount > 0)
                      _InfoRow('Diskon', '- ${formatter.format(transaction.discountAmount)}', valueColor: AppColors.success),
                    _InfoRow('Pajak (${transaction.taxPercentage.toStringAsFixed(0)}%)', formatter.format(transaction.taxAmount)),
                    if (transaction.rounding != 0)
                      _InfoRow('Pembulatan', formatter.format(transaction.rounding)),
                    const Divider(color: AppColors.border),
                    _InfoRow('TOTAL', formatter.format(transaction.total), bold: true, valueColor: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.print_rounded),
                label: const Text('Cetak Ulang Struk'),
                onPressed: () {},
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

final _transactionDetailProvider = FutureProvider.family<(TransactionModel, List<TransactionItem>)?, String>((ref, id) async {
  final db = DatabaseHelper.instance;
  final maps = await db.rawQuery('''
    SELECT t.*, u.name as cashier_name, c.name as customer_name
    FROM transactions t
    LEFT JOIN users u ON t.cashier_id = u.id
    LEFT JOIN customers c ON t.customer_id = c.id
    WHERE t.id = ?
  ''', [id]);
  if (maps.isEmpty) return null;
  final transaction = TransactionModel.fromMap(maps.first);

  final itemMaps = await db.query('transaction_items', where: 'transaction_id = ?', whereArgs: [id]);
  final items = itemMaps.map((m) => TransactionItem.fromMap(m)).toList();

  return (transaction, items);
});

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ],
    ),
  );
}


