import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- States ---
abstract class DriverHistoryState {}
class DriverHistoryInitial extends DriverHistoryState {}
class DriverHistoryLoading extends DriverHistoryState {}
class DriverHistoryLoaded extends DriverHistoryState {
  final List<QueryDocumentSnapshot> trips;
  DriverHistoryLoaded(this.trips);
}
class DriverHistoryError extends DriverHistoryState {
  final String message;
  DriverHistoryError(this.message);
}

// --- Cubit ---
class DriverHistoryCubit extends Cubit<DriverHistoryState> {
  DriverHistoryCubit() : super(DriverHistoryInitial());

  StreamSubscription? _historySubscription;
  
  // ❌ السطر ده اتمسح من هنا عشان كان بيعلق الإيميل القديم

  void startListeningToHistoryTrips() {
    // ✅ تم النقل هنا: عشان كل مرة تشتغل تجيب الإيميل اللي فاتح حالياً
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    if (currentUserId.isEmpty) return;

    if (state is! DriverHistoryLoaded) {
      if (!isClosed) emit(DriverHistoryLoading());
    }

    _historySubscription?.cancel();

    _historySubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
          
      if (isClosed) return;

      var historyTrips = snapshot.docs.where((doc) {
        var data = doc.data(); 
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        
        String status = data['status'] ?? ''; 
        
        bool isHistoryStatus = status == 'completed' || status == 'canceled' || status == 'cancelled';
                             
        return isNotDeleted && isHistoryStatus;
      }).toList();

      historyTrips.sort((a, b) {
        var dataA = a.data();
        var dataB = b.data();
        Timestamp? timeA = dataA['createdAt'];
        Timestamp? timeB = dataB['createdAt'];
        
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); 
      });

      if (!isClosed) emit(DriverHistoryLoaded(historyTrips));
      
    }, onError: (error) {
      if (!isClosed) emit(DriverHistoryError('حدث خطأ في تحميل السجل.'));
    });
  }

  // =======================================================
  // 🟢 دالة إلغاء الرحلة بالكامل (Soft Delete + تنظيف الحجوزات)
  // =======================================================
  Future<void> cancelDriverTrip(String tripId) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      batch.update(tripRef, {
        'status': 'canceled',
        'isDeleted': true, 
        'canceledAt': FieldValue.serverTimestamp(),
      });

      var bookingsSnapshot = await FirebaseFirestore.instance
          .collection('trip_bookings')
          .where('tripId', isEqualTo: tripId)
          .get();

      for (var doc in bookingsSnapshot.docs) {
        batch.delete(doc.reference); 
      }

      await batch.commit();
      debugPrint('✅ تم إلغاء الرحلة وتنظيف الحجوزات المرتبطة بها بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في إلغاء رحلة الكابتن: $e');
      if (!isClosed) emit(DriverHistoryError('حدث خطأ أثناء إلغاء الرحلة'));
    }
  }

  // =======================================================
  // 🟢 دالة مسح الرحلة من السجل الشخصي للكابتن فقط
  // =======================================================
  Future<void> deleteTripFromHistory(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'isDeletedForDriver': true,
      });
      debugPrint('✅ تم إخفاء الرحلة من سجل الكابتن');
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب من السجل: $e');
      if (!isClosed) emit(DriverHistoryError('حدث خطأ أثناء مسح الرحلة من السجل'));
    }
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}