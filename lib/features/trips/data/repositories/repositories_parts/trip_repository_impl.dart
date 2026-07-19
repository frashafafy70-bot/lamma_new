import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dartz/dartz.dart';

// 🟢 مسارات مطلقة
import 'package:lamma_new/core/errors/failures.dart';
import 'package:lamma_new/features/trips/domain/repositories/trip_repository.dart';
import 'package:lamma_new/features/trips/domain/repositories/booking_repository.dart'; // 🟢 تمت إضافة الـ Import هنا
import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';

// 🟢 أسماء الملفات مباشرة (لأنهم في نفس الفولدر)
part 'trip_crud.dart';
part 'trip_booking_repository.dart';
part 'trip_negotiation_repository.dart';
part 'trip_tracking_repository.dart';
part 'trip_queries_repository.dart';

abstract class TripRepositoryBase {
  FirebaseFirestore get firestore;
  FirebaseAuth get auth;
  SharedPreferences get prefs;
  String get collectionName => 'trips';

  TripModel toModel(TripEntity trip) {
    return TripModel(
      id: trip.id,
      isDriverPost: trip.isDriverPost,
      driverId: trip.driverId,
      driverName: trip.driverName,
      passengerId: trip.passengerId,
      passengerName: trip.passengerName,
      tripCategory: trip.tripCategory,
      vehicleType: trip.vehicleType,
      pickup: trip.pickup,
      destination: trip.destination,
      pickupLocation: trip.pickupLocation,
      destinationLocation: trip.destinationLocation,
      fromCity: trip.fromCity,
      toCity: trip.toCity,
      fromLocation: trip.fromLocation,
      toLocation: trip.toLocation,
      time: trip.time,
      travelDate: trip.travelDate,
      tripType: trip.tripType,
      availableSeats: trip.availableSeats,
      suggestedPrice: trip.suggestedPrice,
      price: trip.price,
      seatPrice: trip.seatPrice,
      fullCarPrice: trip.fullCarPrice,
      finalPrice: trip.finalPrice,
      negotiationPrice: trip.negotiationPrice,
      lastNegotiator: trip.lastNegotiator,
      errandDetails: trip.errandDetails,
      errandCost: trip.errandCost,
      audioUrl: trip.audioUrl,
      status: trip.status,
      createdAt: trip.createdAt,
    );
  }
}

class TripRepositoryImpl extends TripRepositoryBase
    with
        TripCoreRepository,
        TripBookingRepositoryMixin,
        TripNegotiationRepository,
        TripTrackingRepository,
        TripQueriesRepository
    implements TripRepository, BookingRepository {
  // 🟢 تم التعديل هنا بإضافة BookingRepository

  @override
  final FirebaseFirestore firestore;
  @override
  final FirebaseAuth auth;
  @override
  final SharedPreferences prefs;

  TripRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required this.prefs,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;
}
