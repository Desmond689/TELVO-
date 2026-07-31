// lib/models/admin_model.dart

class AdminModel {
  AdminModel({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.role = 'admin',
    this.permissions = const [],
    this.isActive = true,
    this.lastLogin,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) => AdminModel(
    id: id,
    userId: map['userId'] as String? ?? '',
    email: map['email'] as String? ?? '',
    fullName: map['fullName'] as String?,
    role: map['role'] as String? ?? 'admin',
    permissions: List<String>.from(map['permissions'] ?? const []),
    isActive: map['isActive'] as bool? ?? true,
    lastLogin: map['lastLogin']?.toDate(),
  );

  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? lastLogin;

  bool get isSuperAdmin => role == 'super_admin';
}
