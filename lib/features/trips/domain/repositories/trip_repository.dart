import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';
import '../entities/trip_entity.dart';

abstract class TripRepository {
  // ==========================================
  // 1. الدوال الأساسية 
  // ==========================================
  Stream<List<TripEntity>> getTrips();
  Stream<List<TripEntity>> getUserTrips(String userId);
  Future<TripEntity?> getTripById(String tripId);
  Future<Either<Failure, void>> addTrip(TripEntity trip);
  Future<Either<Failure, void>> updateTrip(TripEntity trip);
  Future<Either<Failure, void>> deleteTrip(String tripId);

  // ==========================================
  // 2. دوال إنشاء الطلبات
  // ==========================================
  Future<Either<Failure, String>> createPassengerTrip({
    required String tripCategory,
    required String vehicleType,
    required String pickup,
    required String destination,
    required String price,
    String? errandDetails,
    String? errandCost,
    File? orderAudioFile,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
  });
  
  Future<Either<Failure, void>> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  });
  
  Future<Either<Failure, void>> addTravelTrip(TripModel trip);
  
  // ==========================================
  // 3. دوال الجلب (Streams & Queries)
  // ==========================================
  Stream<List<TripModel>> getTripsStream(String userId, {bool isPassenger = true});
  Stream<int> getDriverActiveOrdersCountStream(String uid);
  Stream<int> getPassengerActiveOrdersCountStream(String uid);
  
  Future<Either<Failure, List<TripModel>>> getDriverActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  });
  
  Future<Either<Failure, List<TripModel>>> getPassengerActiveTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  });
  
  Future<Either<Failure, List<TripModel>>> getDriverHistoryTrips({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  });
  
  Future<Either<Failure, List<TripModel>>> getAvailableTravels({
    required int limit,
    TripModel? lastTrip,
  });

  // ==========================================
  // 4. دوال الحجز والتفاوض 
  // ==========================================
  Future<Either<Failure, void>> acceptPassengerBooking({
    required String bookingId,
    required String tripId,
    required int seatsToDeduct,
  });

  Future<Either<Failure, void>> rejectPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
  });

  Future<Either<Failure, void>> cancelPassengerBooking({
    required String bookingId,
    required String tripId,
    required String passengerId,
    required int seatsToReturn,
    required bool wasAccepted,
  });

  Future<Either<Failure, void>> updateBookingSeats({
    required String bookingId,
    required int newSeats,
    required DateTime travelDate,
  });

  Future<Either<Failure, void>> submitNegotiation({
    required String docId,
    required double offerPrice,
    required bool isDriver,
  });

  Future<Either<Failure, void>> acceptTripOffer({
    required String tripId,
    required String finalPrice,
    required bool isDriver,
    required String currentUserId,
  });

  Future<Either<Failure, void>> rejectTripOffer({
    required String tripId,
  });

  // 🟢 الدالة الجديدة لحجز مقعد في رحلة سفر
  Future<Either<Failure, void>> bookSeatInDriverPost({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  });

  // ==========================================
  // 5. دوال تتبع الرحلة وتحديث الحالة
  // ==========================================
  Future<Either<Failure, void>> activateDriverTripFunction(String tripId, String driverId);
  Future<Either<Failure, void>> updateTripStatus(String tripId, String status); 
  
  Future<Either<Failure, void>> syncDriverLocation(String tripId, double lat, double lng);
  
  Future<Either<Failure, bool>> checkHasActiveTrip(String driverId);

  Future<Either<Failure, void>> cancelTrip({
    required String tripId, 
    required bool isDriver,
  });
  
  Future<Either<Failure, void>> startTrip(String tripId);
  Future<Either<Failure, void>> completeTrip(String tripId);

  Future<Either<Failure, void>> submitTripRating({
    required String tripId,
    required double rating,
    required String comment,
  });
  
  Future<Either<Failure, void>> publishTravelTrip(TripModel trip);
}