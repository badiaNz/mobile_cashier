import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../core/database_helper.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final db = DatabaseHelper.instance;
  final maps = await db.query('customers', orderBy: 'name ASC');
  return maps.map((m) => CustomerModel.fromMap(m)).toList();
});

final customerSearchProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<AsyncValue<List<CustomerModel>>>((ref) {
  final customers = ref.watch(customersProvider);
  final search = ref.watch(customerSearchProvider);
  return customers.whenData((list) {
    if (search.isEmpty) return list;
    final q = search.toLowerCase();
    return list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.phone?.contains(q) ?? false) ||
        (c.email?.toLowerCase().contains(q) ?? false)).toList();
  });
});

class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _db;
  final Ref _ref;

  CustomerNotifier(this._db, this._ref) : super(const AsyncData(null));

  Future<bool> addCustomer(CustomerModel customer) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now().toIso8601String();
      await _db.insert('customers', {
        ...customer.toMap(),
        'id': _uuid.v4(),
        'created_at': now,
        'updated_at': now,
      });
      _ref.invalidate(customersProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    state = const AsyncLoading();
    try {
      await _db.update(
        'customers',
        {...customer.toMap(), 'updated_at': DateTime.now().toIso8601String()},
        'id = ?',
        [customer.id],
      );
      _ref.invalidate(customersProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    state = const AsyncLoading();
    try {
      await _db.delete('customers', 'id = ?', [id]);
      _ref.invalidate(customersProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
  return CustomerNotifier(DatabaseHelper.instance, ref);
});

// Employees (uses users table)
final employeesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.query('users', orderBy: 'name ASC');
});
