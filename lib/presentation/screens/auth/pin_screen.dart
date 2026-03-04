import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  final int _pinLength = 4;

  void _addDigit(String digit) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += digit);
      if (_pin.length == _pinLength) {
        _submitPin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _submitPin() async {
    final success = await ref.read(authStateProvider.notifier).loginWithPin(_pin);
    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN tidak valid'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.lock_rounded, size: 60, color: AppColors.primary)
                  .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              const Text('Masukkan PIN',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('PIN 4 digit untuk masuk',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 50),
              // Number pad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']])
                      Row(
                        children: row.map((key) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: AspectRatio(
                              aspectRatio: 1.5,
                              child: Material(
                                color: key.isEmpty ? Colors.transparent : AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: key.isEmpty ? null : key == '⌫' ? _removeDigit : () => _addDigit(key),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: key == '⌫'
                                        ? const Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 22)
                                        : key.isNotEmpty
                                            ? Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary))
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Masuk dengan Email'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

