import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lamma_new/features/trips/data/models/trip_model.dart';

// 🟢 المعمارية النظيفة (Use Cases)
import '../../domain/usecases/cancel_trip_use_case.dart'; 
import '../../domain/usecases/update_booking_seats_use_case.dart';
import '../../domain/usecases/submit_negotiation_use_case.dart';
import '../../domain/usecases/start_trip_use_case.dart';
import '../../domain/usecases/complete_trip_use_case.dart';
import '../../domain/usecases/accept_trip_offer_use_case.dart';
import '../../domain/usecases/reject_trip_offer_use_case.dart';
import '../../domain/usecases/submit_trip_rating_use_case.dart';
import '../../domain/usecases/publish_travel_trip_use_case.dart';
import '../../domain/usecases/sync_driver_location_use_case.dart';

import 'trip_actions_state.dart';

class TripActionsCubit extends Cubit<TripActionsState> {
  final CancelTripUseCase cancelTripUseCase;
  final UpdateBookingSeatsUseCase updateBookingSeatsUseCase;
  final SubmitNegotiationUseCase submitNegotiationUseCase;
  final StartTripUseCase startTripUseCase;
  final CompleteTripUseCase completeTripUseCase;
  final AcceptTripOfferUseCase acceptTripOfferUseCase;
  final RejectTripOfferUseCase rejectTripOfferUseCase;
  final SubmitTripRatingUseCase submitTripRatingUseCase;
  final PublishTravelTripUseCase publishTravelTripUseCase;
  final SyncDriverLocationUseCase syncDriverLocationUseCase;

  TripActionsCubit({
    required this.cancelTripUseCase,
    required this.updateBookingSeatsUseCase,
    required this.submitNegotiationUseCase,
    required this.startTripUseCase,
    required this.completeTripUseCase,
    required this.acceptTripOfferUseCase,
    required this.rejectTripOfferUseCase,
    required this.submitTripRatingUseCase,
    required this.publishTravelTripUseCase,
    required this.syncDriverLocationUseCase,
  }) : super(TripActionsInitial());

  // ==========================================
  // 🟢 الدوال النظيفة بالكامل (100% Clean)
  // ==========================================
  
  Future<void> cancelTripFully({required String tripId, required bool isDriver}) async {
    emit(TripActionsLoading());
    final result = await cancelTripUseCase(tripId: tripId, isDriver: isDriver);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بنجاح')),
    );
  }

  Future<void> updateBookingSeats({required String bookingId, required int newSeats, required DateTime travelDate}) async {
    emit(TripActionsLoading());
    final result = await updateBookingSeatsUseCase(bookingId: bookingId, newSeats: newSeats, travelDate: travelDate);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'update_booking', message: 'تم تعديل الحجز بنجاح')),
    );
  }

  Future<void> submitNegotiationOffer({required String docId, required double offerPrice, required bool isDriver}) async {
    emit(TripActionsLoading());
    final result = await submitNegotiationUseCase(docId: docId, offerPrice: offerPrice, isDriver: isDriver);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح')),
    );
  }

  Future<void> sendOffer(TripModel trip, String price, bool isDriver, String currentUserId) async {
    if (price.trim().isEmpty) return;
    if (trip.id == null || trip.id!.isEmpty) {
      emit(TripActionsError("حدث خطأ: معرف الرحلة مفقود."));
      return;
    }

    emit(TripActionsLoading());
    double parsedPrice = double.tryParse(price.trim()) ?? 0.0;
    
    final result = await submitNegotiationUseCase(docId: trip.id!, offerPrice: parsedPrice, isDriver: isDriver);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'negotiate', message: 'تم إرسال العرض بنجاح')),
    );
  }

  Future<void> acceptOffer(TripModel trip, bool isDriver, String currentUserId) async {
    emit(TripActionsLoading());
    String safePrice = trip.negotiationPrice?.toString() ?? trip.price?.toString() ?? trip.suggestedPrice?.toString() ?? '0';

    final result = await acceptTripOfferUseCase(
      tripId: trip.id ?? '',
      finalPrice: safePrice,
      isDriver: isDriver,
      currentUserId: currentUserId,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'accept', message: 'تم قبول الرحلة بنجاح')),
    );
  }

  Future<void> rejectOrCancelTrip(TripModel trip, bool isDriver) async {
    emit(TripActionsLoading());
    if (!isDriver && trip.status == 'negotiating') {
      final result = await rejectTripOfferUseCase(trip.id ?? '');
      if (isClosed) return;
      result.fold(
        (failure) => emit(TripActionsError(failure.message)),
        (_) => emit(TripActionsSuccess(action: 'reject', message: 'تم رفض العرض والعودة للبحث')),
      );
    } else {
      final result = await cancelTripUseCase(tripId: trip.id ?? '', isDriver: isDriver);
      if (isClosed) return;
      result.fold(
        (failure) => emit(TripActionsError(failure.message)),
        (_) => emit(TripActionsSuccess(action: 'cancel', message: 'تم إلغاء الرحلة بالكامل')),
      );
    }
  }

  Future<void> startTrip(String tripId) async {
    emit(TripActionsLoading());
    final result = await startTripUseCase(tripId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'start', message: 'تم بدء الرحلة!')),
    );
  }

  Future<void> completeTrip(String tripId) async {
    emit(TripActionsLoading());
    final result = await completeTripUseCase(tripId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'complete', message: 'رحلة سعيدة!')),
    );
  }

  Future<void> publishTravelPost(TripModel trip) async {
    emit(TripActionsLoading());
    final result = await publishTravelTripUseCase(trip);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'publish', message: 'تم نشر الرحلة بنجاح!')),
    );
  }

  Future<void> addTravelTrip({required TripModel trip}) async {
    await publishTravelPost(trip);
  }

  Future<void> updateDriverLocation(String tripId, GeoPoint location) async {
    await syncDriverLocationUseCase(tripId, location);
  }

  Future<void> submitRating({required String tripId, required double rating, required String comment}) async {
    emit(TripActionsLoading());
    final result = await submitTripRatingUseCase(tripId: tripId, rating: rating, comment: comment);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TripActionsError(failure.message)),
      (_) => emit(TripActionsSuccess(action: 'rate', message: 'شكراً لتقييمك الكابتن!')),
    );
  }
}