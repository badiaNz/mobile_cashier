import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  String? _selectedCategoryId;
  bool _trackStock = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final product = ProductModel(
      id: widget.productId ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      categoryId: _selectedCategoryId,
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      price: double.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
      costPrice: double.tryParse(_costController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 5,
      unit: _unitController.text.trim(),
      isActive: true,
      trackStock: _trackStock,
      hasVariants: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.productId == null) {
      success = await ref.read(productNotifierProvider.notifier).addProduct(product);
    } else {
      success = await ref.read(productNotifierProvider.notifier).updateProduct(product);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.productId == null ? 'Produk ditambahkan' : 'Produk diperbarui'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.productId == null ? 'Tambah Produk' : 'Edit Produk')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image placeholder
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 1)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.textHint, size: 28),
                  SizedBox(height: 4),
                  Text('Foto Produk', style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _Section(title: 'Informasi Produk', children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nama Produk *'),
                validator: (v) => v?.isEmpty == true ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              categories.when(
                data: (cats) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  dropdownColor: AppColors.surfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Pilih Kategori', style: TextStyle(color: AppColors.textHint))),
                    ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon ?? ''} ${c.name}'))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Barcode (Opsional)',
                  prefixIcon: Icon(Icons.qr_code_rounded, color: AppColors.textHint),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Harga', children: [
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Harga Jual *', prefixText: 'Rp '),
                    validator: (v) => v?.isEmpty == true ? 'Harga wajib diisi' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Harga Modal', prefixText: 'Rp '),
                  )),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'Stok', children: [
              SwitchListTile(
                value: _trackStock,
                onChanged: (v) => setState(() => _trackStock = v),
                title: const Text('Lacak Stok', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Non-aktifkan untuk produk tidak terbatas', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                activeColor: AppColors.primary,
                tileColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
              if (_trackStock) ...[
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Stok Awal'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Stok Minimum'),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Satuan (pcs, kg, liter, dll)'),
                ),
              ],
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Produk'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

