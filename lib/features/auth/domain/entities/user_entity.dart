// مسار الملف: lib/features/auth/domain/entities/user_entity.dart

class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String activeRole;

  UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.activeRole,
  });
}