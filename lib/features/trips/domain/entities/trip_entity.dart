import 'package:cloud_firestore/cloud_firestore.dart';

// 🟢 كلاس مخصص لحالات الرحلة
class TripStatus {
  static const String pending = 'pending';
  static const String available = 'available';
  static const String negotiating = 'negotiating';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class TripEntity {
  final String? id;
  final bool isDriverPost;
  final String? driverId;
  final String? driverName;
  final String? passengerId;
  final String? passengerName;
  final String? tripCategory;
  final String? vehicleType;
  final String? pickup;
  final String? destination;
  final GeoPoint? pickupLocation;
  final GeoPoint? destinationLocation;
  final String? fromCity;
  final String? toCity;
  final GeoPoint? fromLocation;
  final GeoPoint? toLocation;
  final String? time;
  final DateTime? travelDate;
  final String? tripType;
  final String? availableSeats;
  final String? suggestedPrice;
  final String? price;
  final String? seatPrice;
  final String? fullCarPrice;
  final String? finalPrice;
  final String? negotiationPrice;
  final String? lastNegotiator;
  final String? errandDetails;
  final String? errandCost;
  final String? audioUrl;
  final String status;
  final DateTime? createdAt;

  TripEntity({
    this.id,
    required this.isDriverPost,
    this.driverId,
    this.driverName,
    this.passengerId,
    this.passengerName,
    this.tripCategory,
    this.vehicleType,
    this.pickup,
    this.destination,
    this.pickupLocation,
    this.destinationLocation,
    this.fromCity,
    this.toCity,
    this.fromLocation,
    this.toLocation,
    this.time,
    this.travelDate,
    this.tripType,
    this.availableSeats,
    this.suggestedPrice,
    this.price,
    this.seatPrice,
    this.fullCarPrice,
    this.finalPrice,
    this.negotiationPrice,
    this.lastNegotiator,
    this.errandDetails,
    this.errandCost,
    this.audioUrl,
    required this.status,
    this.createdAt,
  });
}