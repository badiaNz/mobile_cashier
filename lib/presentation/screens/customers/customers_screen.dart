import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../config/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../../data/models/transaction_model.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(filteredCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manajemen Pelanggan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
              ),
              onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: customers.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_outline_rounded, size: 60, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('Belum ada pelanggan', style: TextStyle(color: AppColors.textSecondary)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(c.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        title: Row(
                          children: [
                            Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _memberColor(c.memberLevel).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text(c.memberLevel, style: TextStyle(color: _memberColor(c.memberLevel), fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.phone != null) Text(c.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            Text('${formatter.format(c.totalSpending)} total belanja  •  ${c.points} poin', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          color: AppColors.surfaceElevated,
                          onSelected: (v) {
                            if (v == 'edit') _showCustomerForm(context, c);
                            if (v == 'delete') ref.read(customerNotifierProvider.notifier).deleteCustomer(c.id);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Edit', style: TextStyle(color: AppColors.textPrimary))])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.error))])),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 30).ms);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Pelanggan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Color _memberColor(String level) {
    switch (level) {
      case 'Platinum': return AppColors.secondary;
      case 'Gold': return AppColors.accentYellow;
      case 'Silver': return AppColors.textSecondary;
      default: return AppColors.accentOrange;
    }
  }

  void _showCustomerForm(BuildContext context, CustomerModel? customer) {
    final nameCtrl = TextEditingController(text: customer?.name);
    final phoneCtrl = TextEditingController(text: customer?.phone);
    final emailCtrl = TextEditingController(text: customer?.email);
    final addressCtrl = TextEditingController(text: customer?.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nama *', prefixIcon: Icon(Icons.person_outline, color: AppColors.textHint))),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'No. HP', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textHint))),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint))),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textHint))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    final c = CustomerModel(
                      id: customer?.id ?? const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                      points: customer?.points ?? 0,
                      totalSpending: customer?.totalSpending ?? 0,
                      createdAt: customer?.createdAt ?? now,
                      updatedAt: now,
                    );
                    if (customer == null) {
                      ref.read(customerNotifierProvider.notifier).addCustomer(c);
                    } else {
                      ref.read(customerNotifierProvider.notifier).updateCustomer(c);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(customer == null ? 'Tambah Pelanggan' : 'Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}


