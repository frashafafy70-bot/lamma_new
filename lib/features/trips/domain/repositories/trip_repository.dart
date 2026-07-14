import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';

abstract class TripRepository {
  Future<void> createNewTripRequest(Map<String, dynamic> tripData);
  
  Future<void> submitTripRequest({
    required String pickupAddress,
    required String dropoffAddress,
    required String price,
    required GeoPoint pickupLocation,
  });
  
  Future<void> addTravelTrip(TripModel trip);
  
  // 🟢 الدالة الجديدة المُضافة للواجهة
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

  Future<Either<Failure, void>> activateDriverTripFunction(String tripId, String driverId);

  // الدوال الخاصة بالخريطة والتتبع الحي
  Future<Either<Failure, void>> updateTripStatus(String tripId, String status);
  
  Future<Either<Failure, void>> syncDriverLocation(String tripId, GeoPoint location);

  // ==========================================
  // 🌟 الدوال الجديدة (Clean Architecture 10/10)
  // ==========================================
  
  Future<Either<Failure, void>> cancelTrip({
    required String tripId, 
    required bool isDriver,
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
}