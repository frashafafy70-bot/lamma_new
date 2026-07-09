import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required String uid,
    required String name,
    required String email,
    required String profileImageUrl,
    required String activeRole,
    String? phone,
    String? nationalId,
    required List<String> roles, // 🟢 إضافة الأدوار
  }) : super(
          uid: uid,
          name: name,
          email: email,
          profileImageUrl: profileImageUrl,
          activeRole: activeRole,
          phone: phone,
          nationalId: nationalId,
          roles: roles,
        );

  factory ProfileModel.fromJson(Map<String, dynamic> json, String uid, String email) {
    return ProfileModel(
      uid: uid,
      name: json['name'] ?? 'مستخدم لَمَّة',
      email: email,
      profileImageUrl: json['profileImage'] ?? '',
      activeRole: json['activeRole'] ?? 'client',
      phone: json['phone'] ?? '',
      nationalId: json['nationalId'] ?? '',
      // 🟢 قراءة مصفوفة الأدوار من الفايربيز بشكل آمن
      roles: json['roles'] != null ? List<String>.from(json['roles']) : ['client'],
    );
  }
}