import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../../data/models/transaction_model.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  final _amountController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _isProcessing = false;

  final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _amountController.text = cart.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final cart = ref.read(cartProvider);

    if (amount < cart.total && _selectedPayment == PaymentMethod.cash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran kurang'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final transaction = await ref.read(cartProvider.notifier).checkout(amount);
    setState(() => _isProcessing = false);

    if (transaction != null && mounted) {
      // Simpan navigator context SEBELUM pop, agar dialog bisa show setelah bottom sheet closed
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final savedContext = context;
      Navigator.pop(context);
      // Tunggu animasi close bottom sheet selesai, lalu tampilkan dialog
      Future.delayed(const Duration(milliseconds: 300), () {
        if (rootNavigator.context.mounted) {
          _showSuccessDialogWithContext(savedContext, rootNavigator, transaction, amount);
        }
      });
    }
  }

  void _showSuccessDialogWithContext(BuildContext ctx, NavigatorState nav, TransactionModel transaction, double amountPaid) {
    final fmt = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    showDialog(
      context: nav.context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(transaction.invoiceNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _ReceiptRow('Total', fmt.format(transaction.total), bold: true),
                  _ReceiptRow('Bayar', fmt.format(amountPaid)),
                  if (transaction.changeAmount > 0)
                    _ReceiptRow('Kembalian', fmt.format(transaction.changeAmount), color: AppColors.accentGreen),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => nav.pop(),
            child: const Text('Selesai'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Cetak Struk'),
            onPressed: () => nav.pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Keranjang Belanja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Hapus Semua'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  ),
                ],
              ),
            ),
            // Cart items
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cart.items.length,
                itemBuilder: (context, i) {
                  final item = cart.items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.fastfood_rounded, color: AppColors.textHint, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                              if (item.discountPercentage > 0)
                                Text('Diskon ${item.discountPercentage.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.success, fontSize: 10)),
                              Text(formatter.format(item.subtotal), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        // Quantity controls
                        Row(
                          children: [
                            _QtyBtn(icon: Icons.remove, color: AppColors.accent, onTap: () {
                              ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('${item.quantity}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                            _QtyBtn(icon: Icons.add, color: AppColors.primary, onTap: () {
                              ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1);
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _ReceiptRow('Subtotal', formatter.format(cart.subtotal)),
                  if (cart.discountAmount > 0)
                    _ReceiptRow('Diskon', '- ${formatter.format(cart.discountAmount)}', color: AppColors.success),
                  _ReceiptRow('Pajak (${cart.taxPercentage.toStringAsFixed(0)}%)', formatter.format(cart.taxAmount)),
                  if (cart.rounding != 0)
                    _ReceiptRow('Pembulatan', formatter.format(cart.rounding)),
                  const Divider(color: AppColors.border),
                  _ReceiptRow('TOTAL', formatter.format(cart.total), bold: true, size: 16),
                  const SizedBox(height: 14),
                  // Payment method
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PaymentMethod.values.map((m) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedPayment = m);
                          ref.read(cartProvider.notifier).setPaymentMethod(m);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPayment == m ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedPayment == m ? AppColors.primary : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(m.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(m.label, style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedPayment == m ? AppColors.primary : AppColors.textSecondary,
                              )),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Amount paid
                  if (_selectedPayment == PaymentMethod.cash) ...[
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Bayar',
                        prefixIcon: Icon(Icons.payments_outlined, color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick amount buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [cart.total, cart.total + 5000, cart.total + 10000, 50000, 100000].map((amount) =>
                          GestureDetector(
                            onTap: () => _amountController.text = amount.toStringAsFixed(0),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                              child: Text(formatter.format(amount), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processCheckout,
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(_isProcessing ? 'Memproses...' : 'Bayar ${formatter.format(cart.total)}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final double size;
  final Color? color;

  const _ReceiptRow(this.label, this.value, {this.bold = false, this.size = 13, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? AppColors.textPrimary)),
      ],
    ),
  );
}


