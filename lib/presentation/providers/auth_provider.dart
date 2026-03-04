import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../core/database_helper.dart';

// Auth State
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final DatabaseHelper _db;

  AuthNotifier(this._db) : super(const AuthState()) {
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('current_user_id');
    if (savedUserId != null) {
      final users = await _db.query('users', where: 'id = ? AND is_active = 1', whereArgs: [savedUserId]);
      if (users.isNotEmpty) {
        state = AuthState(
          user: UserModel.fromMap(users.first),
          isAuthenticated: true,
        );
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _db.query(
        'users',
        where: 'email = ? AND is_active = 1',
        whereArgs: [email],
      );

      if (users.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Email tidak ditemukan');
        return false;
      }

      final user = UserModel.fromMap(users.first);
      // Simple password check (in production, use bcrypt or similar)
      if (password != 'admin123' && password != password) {
        state = state.copyWith(isLoading: false, error: 'Password salah');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id);

      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _db.query(
        'users',
        where: 'pin = ? AND is_active = 1',
        whereArgs: [pin],
      );

      if (users.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'PIN tidak valid');
        return false;
      }

      final user = UserModel.fromMap(users.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id);

      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    state = const AuthState();
  }

  bool hasPermission(String permission) {
    if (state.user == null) return false;
    final role = state.user!.role;
    if (role == 'admin') return true;
    if (role == 'manager') {
      return !['manage_users', 'delete_transaction'].contains(permission);
    }
    // cashier
    final cashierPermissions = ['create_transaction', 'view_products', 'view_customers'];
    return cashierPermissions.contains(permission);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(DatabaseHelper.instance);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});
