import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.roles,
    required super.activeRole,
  });

  // الدالة دي بتاخد البيانات اللي راجعة من Firestore وتحولها للموديل بتاعنا
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      // بنعمل كاستنج للـ List عشان الفايربيس بيرجعها dynamic
      roles: List<String>.from(json['roles'] ?? ['client']),
      activeRole: json['activeRole'] ?? 'client',
    );
  }

  // الدالة دي لو حبينا نرفع الموديل للفايربيس في أي وقت
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'activeRole': activeRole,
    };
  }
}