import 'dart:async';
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
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void startListeningToHistoryTrips() {
    if (currentUserId.isEmpty) return;

    if (state is! DriverHistoryLoaded) {
      emit(DriverHistoryLoading());
    }

    _historySubscription?.cancel();

    _historySubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
          
      var historyTrips = snapshot.docs.where((doc) {
        var data = doc.data(); 
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        
        // 🟢 حماية من الـ null لو الحقل مش موجود
        String status = data['status'] ?? ''; 
        
        // 🟢 تم تصحيح الـ spelling ليشمل 'canceled' بـ L واحدة (المستخدمة في الـ Backend) 
        // و 'cancelled' بـ 2 L عشان لو في داتا قديمة متسجلة كده
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

      emit(DriverHistoryLoaded(historyTrips));
      
    }, onError: (error) {
      emit(DriverHistoryError('حدث خطأ في تحميل السجل.'));
    });
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}