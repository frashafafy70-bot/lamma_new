class ProfileEntity {
  final String uid;
  final String name;
  final String email;
  final String profileImageUrl;
  final String activeRole;
  final String? phone;
  final String? nationalId;
  final List<String> roles; // 🟢 تم إضافة قائمة الأدوار هنا

  ProfileEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.activeRole,
    this.phone,
    this.nationalId,
    this.roles = const ['client'], // القيمة الافتراضية دايماً عميل
  });
}