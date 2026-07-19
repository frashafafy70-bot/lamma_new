// مسار الملف: lib/features/trips/domain/entities/trip_entity.dart

import 'package:equatable/equatable.dart';

// تأكد من تعديل المسارات دي حسب مكان الملفين عندك في المشروع
import 'trip_status.dart';
import '../../../../core/entities/location_coordinates.dart';

class TripEntity extends Equatable {
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

  // استخدام كلاس الإحداثيات النظيف
  final LocationCoordinates? pickupLocation;
  final LocationCoordinates? destinationLocation;
  final String? fromCity;
  final String? toCity;
  final LocationCoordinates? fromLocation;
  final LocationCoordinates? toLocation;

  final String? time;
  final DateTime? travelDate;
  final String? tripType;

  // أرقام صحيحة للمقاعد
  final int? availableSeats;

  // تحويل جميع القيم المالية إلى double لسهولة العمليات الحسابية
  final double? suggestedPrice;
  final double? price;
  final double? seatPrice;
  final double? fullCarPrice;
  final double? finalPrice;
  final double? negotiationPrice;
  final double? errandCost;

  final String? lastNegotiator;
  final String? errandDetails;
  final String? audioUrl;

  // الاعتماد على الـ Enum
  final TripStatus status;
  final DateTime? createdAt;

  const TripEntity({
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

  @override
  List<Object?> get props => [
        id,
        isDriverPost,
        status,
        price,
        finalPrice,
        pickupLocation,
        destinationLocation,
        availableSeats,
      ];
}
