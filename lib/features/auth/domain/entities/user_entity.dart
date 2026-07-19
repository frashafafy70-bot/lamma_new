class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String activeRole;

  // 🟢 ضفنا الـ Getter ده عشان الـ AuthCubit يقدر يقرأ الاختصاص مباشرة باسم role
  String get role => activeRole;

  UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.activeRole,
  });
}
