import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? pin;
  final String role; // admin, cashier, manager
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.pin,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      pin: map['pin'] as String?,
      role: map['role'] as String,
      avatarUrl: map['avatar_url'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'pin': pin,
    'role': role,
    'avatar_url': avatarUrl,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  UserModel copyWith({
    String? name,
    String? email,
    String? pin,
    String? role,
    String? avatarUrl,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';

  @override
  List<Object?> get props => [id, name, email, role, isActive];
}
