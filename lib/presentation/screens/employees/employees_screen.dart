import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../config/app_theme.dart';
import '../../providers/customer_provider.dart';
import '../../../core/database_helper.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manajemen Pegawai')),
      body: employees.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final e = list[i];
            final name = e['name'] as String? ?? '-';
            final email = e['email'] as String? ?? '-';
            final role = e['role'] as String? ?? 'cashier';
            final isActive = (e['is_active'] as int? ?? 1) == 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _roleColor(role).withOpacity(0.15),
                    child: Text(name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text(_roleLabel(role), style: TextStyle(color: _roleColor(role), fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployee(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Pegawai', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppColors.accent;
      case 'manager': return AppColors.accentOrange;
      default: return AppColors.primary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'ADMIN';
      case 'manager': return 'MANAJER';
      default: return 'KASIR';
    }
  }

  void _showAddEmployee(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String selectedRole = 'cashier';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setLS) => Padding(
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
                const Text('Tambah Pegawai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Nama Lengkap *')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 12),
                TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'PIN (4 digit)', counterText: '')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
                  decoration: const InputDecoration(labelText: 'Peran'),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('Kasir')),
                    DropdownMenuItem(value: 'manager', child: Text('Manajer')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setLS(() => selectedRole = v ?? 'cashier'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                      final now = DateTime.now().toIso8601String();
                      await DatabaseHelper.instance.insert('users', {
                        'id': const Uuid().v4(),
                        'name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'pin': pinCtrl.text.trim().isEmpty ? null : pinCtrl.text.trim(),
                        'role': selectedRole,
                        'is_active': 1,
                        'created_at': now,
                        'updated_at': now,
                      });
                      ref.invalidate(employeesProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Tambah Pegawai'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

