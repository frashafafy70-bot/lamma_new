import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/trip_repository.dart'; // مسار الـ Repo
import '../../data/models/trip_model.dart';
import 'driver_history_state.dart';

class DriverHistoryCubit extends Cubit<DriverHistoryState> {
  final TripRepository _repository; // الـ Dependency Injection (ممكن تستخدم UseCase لو حابب)
  
  List<TripModel> _trips = [];
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;
  final int _limit = 15;

  DriverHistoryCubit(this._repository) : super(DriverHistoryInitial());

  // --------------------------------------------------
  // 🔥 نظام الـ Pagination
  // --------------------------------------------------
  void startListeningToHistoryTrips() {
    fetchInitialHistoryTrips();
  }

  Future<void> fetchInitialHistoryTrips() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    emit(DriverHistoryLoading());
    
    _trips.clear();
    _hasReachedMax = false;
    _isFetchingMore = false;

    try {
      final result = await _repository.getDriverHistoryTrips(uid: currentUserId, limit: _limit);

      if (isClosed) return;

      result.fold(
        (failure) => emit(DriverHistoryError('حدث خطأ في تحميل السجل.')),
        (trips) {
          _trips = trips;
          _hasReachedMax = trips.length < _limit;
          emit(DriverHistoryLoaded(
            trips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      if (!isClosed) emit(DriverHistoryError('حدث خطأ غير متوقع'));
    }
  }

  Future<void> fetchMoreHistoryTrips() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_hasReachedMax || _isFetchingMore || currentUserId.isEmpty) return;

    _isFetchingMore = true;
    if (state is DriverHistoryLoaded) {
      emit((state as DriverHistoryLoaded).copyWith(isFetchingMore: true));
    }

    try {
      final lastTrip = _trips.isNotEmpty ? _trips.last : null;
      final result = await _repository.getDriverHistoryTrips(
        uid: currentUserId, limit: _limit, lastTrip: lastTrip
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _isFetchingMore = false;
          if (state is DriverHistoryLoaded) {
            emit((state as DriverHistoryLoaded).copyWith(isFetchingMore: false));
          }
        },
        (newTrips) {
          _isFetchingMore = false;
          if (newTrips.isEmpty) {
            _hasReachedMax = true;
          } else {
            _trips.addAll(newTrips);
            _hasReachedMax = newTrips.length < _limit;
          }
          emit(DriverHistoryLoaded(
            trips: List.from(_trips),
            hasReachedMax: _hasReachedMax,
            isFetchingMore: false,
          ));
        },
      );
    } catch (e) {
      _isFetchingMore = false;
      if (state is DriverHistoryLoaded && !isClosed) {
        emit((state as DriverHistoryLoaded).copyWith(isFetchingMore: false));
      }
    }
  }

  // --------------------------------------------------
  // 🔥 اللوجيك القديم الخاص بالسائق
  // --------------------------------------------------
  
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
      
      fetchInitialHistoryTrips(); // تحديث القائمة

    } catch (e) {
      debugPrint('❌ خطأ في إلغاء رحلة الكابتن: $e');
      if (!isClosed) emit(DriverHistoryError('حدث خطأ أثناء إلغاء الرحلة'));
    }
  }

  Future<void> deleteTripFromHistory(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(docId).update({
        'isDeletedForDriver': true,
      });
      debugPrint('✅ تم إخفاء الرحلة من سجل الكابتن');
      
      fetchInitialHistoryTrips(); // تحديث القائمة

    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب من السجل: $e');
      if (!isClosed) emit(DriverHistoryError('حدث خطأ أثناء مسح الرحلة من السجل'));
    }
  }
}