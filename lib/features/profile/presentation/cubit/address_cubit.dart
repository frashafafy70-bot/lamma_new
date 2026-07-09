import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- حالات الكيوبت (States) ---
abstract class AddressState {}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<Map<String, dynamic>> addresses;
  AddressLoaded(this.addresses);
}

class AddressError extends AddressState {
  final String message;
  AddressError(this.message);
}

// --- الكيوبت (Cubit) ---
class AddressCubit extends Cubit<AddressState> {
  AddressCubit() : super(AddressInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. جلب العناوين من فايربيز
  Future<void> fetchAddresses() async {
    emit(AddressLoading());
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(AddressError('المستخدم غير مسجل الدخول'));
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .orderBy('createdAt', descending: true) // جلب الأحدث أولاً
          .get();

      final addresses = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      emit(AddressLoaded(addresses));
    } catch (e) {
      emit(AddressError('حدث خطأ أثناء جلب العناوين: ${e.toString()}'));
    }
  }

  // 2. إضافة عنوان جديد
  Future<void> addAddress(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // لو العنوان ده هو الأساسي، نشيل الأساسي من باقي العناوين الأول
      if (data['isDefault'] == true) {
        await _removeDefaultStatus(user.uid);
      }

      // إضافة طابع زمني للتأكد من الترتيب
      final addressData = {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .add(addressData);

      await fetchAddresses(); // تحديث القائمة
    } catch (e) {
      emit(AddressError('حدث خطأ أثناء الإضافة: ${e.toString()}'));
    }
  }

  // 3. تعديل عنوان موجود
  Future<void> updateAddress(String docId, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      if (data['isDefault'] == true) {
        await _removeDefaultStatus(user.uid);
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .doc(docId)
          .update(data);

      await fetchAddresses(); // تحديث القائمة
    } catch (e) {
      emit(AddressError('حدث خطأ أثناء التعديل: ${e.toString()}'));
    }
  }

  // 4. حذف عنوان
  Future<void> deleteAddress(String docId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .doc(docId)
          .delete();

      await fetchAddresses(); // تحديث القائمة
    } catch (e) {
      emit(AddressError('حدث خطأ أثناء الحذف: ${e.toString()}'));
    }
  }

  // دالة مساعدة لإلغاء حالة "الأساسي" من العناوين القديمة
  Future<void> _removeDefaultStatus(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}