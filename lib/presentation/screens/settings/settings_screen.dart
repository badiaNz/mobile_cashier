import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../../core/database_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final storeSettingsAsync = ref.watch(_storeSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    (user?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '-', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(user?.email ?? '-', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          (user?.role ?? 'cashier').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),

          // Store settings
          storeSettingsAsync.when(
            data: (settings) => _Section(
              title: 'Toko',
              icon: Icons.store_rounded,
              children: [
                _SettingsTile(
                  icon: Icons.store_outlined,
                  label: 'Nama Toko',
                  value: settings['store_name']?.toString() ?? 'Toko Saya',
                  onTap: () => _editField(context, 'Nama Toko', settings['store_name']?.toString() ?? '', (v) async {
                    await DatabaseHelper.instance.rawUpdate('UPDATE store_settings SET store_name = ? WHERE id = 1', [v]);
                    (context as Element).markNeedsBuild();
                  }),
                ),
                _SettingsTile(
                  icon: Icons.phone_outlined,
                  label: 'No. Telepon',
                  value: settings['phone']?.toString() ?? '-',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: settings['address']?.toString() ?? '-',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.receipt_outlined,
                  label: 'Pajak (PPN)',
                  value: '${settings['tax_percentage']}%',
                  onTap: () {},
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          _Section(
            title: 'Preferensi',
            icon: Icons.tune_rounded,
            children: [
              _SettingsTile(icon: Icons.print_outlined, label: 'Printer', value: 'Tidak dikonfigurasi', onTap: () {}),
              _SettingsTile(icon: Icons.qr_code_rounded, label: 'QRIS', value: 'Belum diatur', onTap: () {}),
              _SettingsTile(icon: Icons.currency_exchange_rounded, label: 'Mata Uang', value: 'IDR - Rupiah', onTap: () {}),
              _SettingsTile(icon: Icons.dark_mode_outlined, label: 'Tema', value: 'Dark Mode', onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),

          if (user?.isManager == true)
            _Section(
              title: 'Data & Backup',
              icon: Icons.storage_rounded,
              children: [
                _SettingsTile(icon: Icons.backup_rounded, label: 'Backup Data', value: 'Export ke file', onTap: () {}),
                _SettingsTile(icon: Icons.restore_rounded, label: 'Pulihkan Data', value: 'Import dari file', onTap: () {}),
                _SettingsTile(icon: Icons.delete_sweep_rounded, label: 'Hapus Data Lama', value: 'Transaksi > 1 tahun', onTap: () {}),
              ],
            ),
          const SizedBox(height: 12),

          _Section(
            title: 'Tentang',
            icon: Icons.info_outline_rounded,
            children: [
              _SettingsTile(icon: Icons.info_outlined, label: 'Versi Aplikasi', value: '1.0.0', onTap: () {}),
              _SettingsTile(icon: Icons.policy_outlined, label: 'Kebijakan Privasi', value: '', onTap: () {}),
              _SettingsTile(icon: Icons.help_outline_rounded, label: 'Bantuan', value: '', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _editField(BuildContext context, String label, String currentValue, Future<void> Function(String) onSave) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit $label', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () async {
            await onSave(ctrl.text);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 0),
        ...children,
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: AppColors.textSecondary, size: 20),
    title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.isNotEmpty) Text(value, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
      ],
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

final _storeSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  final results = await db.query('store_settings', limit: 1);
  return results.isNotEmpty ? results.first : {};
});

