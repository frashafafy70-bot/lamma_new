import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member_model.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // البحث عن مستخدم برقم الهاتف
  Future<Map<String, dynamic>?> findUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'uid': doc.id,
          ...doc.data(),
        };
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء البحث عن المستخدم: $e');
    }
  }

  // إضافة فرد للعائلة
  Future<void> addFamilyMember(String parentUid, Map<String, dynamic> childData) async {
    try {
      final childUid = childData['uid'];
      
      final familyMember = FamilyMember(
        uid: childUid,
        name: childData['name'] ?? 'مستخدم',
        phoneNumber: childData['phone'] ?? '',
        isTrackingEnabled: true,
      );

      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('family_members')
          .doc(childUid)
          .set(familyMember.toMap());
    } catch (e) {
      throw Exception('حدث خطأ أثناء إضافة فرد العائلة: $e');
    }
  }

  // جلب قائمة أفراد العائلة
  Stream<List<FamilyMember>> getFamilyMembersStream(String parentUid) {
    return _firestore
        .collection('users')
        .doc(parentUid)
        .collection('family_members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // حذف فرد من العائلة
  Future<void> removeFamilyMember(String parentUid, String childUid) async {
    try {
      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('family_members')
          .doc(childUid)
          .delete();
    } catch (e) {
      throw Exception('حدث خطأ أثناء إزالة فرد العائلة: $e');
    }
  }
}