import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
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
  final String? availableSeats;
  final String? suggestedPrice; 
  final String? price; 
  final String? finalPrice;
  final String? negotiationPrice;
  final String? lastNegotiator;
  final String? errandDetails;
  final String? errandCost;
  final String? audioUrl;
  final String status;
  final DateTime? createdAt;

  TripModel({
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
    this.availableSeats,
    this.suggestedPrice,
    this.price,
    this.finalPrice,
    this.negotiationPrice,
    this.lastNegotiator,
    this.errandDetails,
    this.errandCost,
    this.audioUrl,
    required this.status,
    this.createdAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripModel(
      id: documentId,
      isDriverPost: map['isDriverPost'] ?? false,
      driverId: map['driverId'],
      driverName: map['driverName'],
      passengerId: map['passengerId'],
      passengerName: map['passengerName'],
      tripCategory: map['tripCategory'],
      vehicleType: map['vehicleType'],
      pickup: map['pickup'],
      destination: map['destination'],
      pickupLocation: map['pickupLocation'],
      destinationLocation: map['destinationLocation'],
      fromCity: map['fromCity'],
      toCity: map['toCity'],
      fromLocation: map['fromLocation'],
      toLocation: map['toLocation'],
      time: map['time'],
      availableSeats: map['availableSeats']?.toString(),
      suggestedPrice: map['suggestedPrice']?.toString(),
      price: map['price']?.toString(),
      finalPrice: map['finalPrice']?.toString(),
      negotiationPrice: map['negotiationPrice']?.toString(),
      lastNegotiator: map['lastNegotiator'],
      errandDetails: map['errandDetails'],
      errandCost: map['errandCost']?.toString(),
      audioUrl: map['audioUrl'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDriverPost': isDriverPost,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (passengerId != null) 'passengerId': passengerId,
      if (passengerName != null) 'passengerName': passengerName,
      if (tripCategory != null) 'tripCategory': tripCategory,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (pickup != null) 'pickup': pickup,
      if (destination != null) 'destination': destination,
      if (pickupLocation != null) 'pickupLocation': pickupLocation,
      if (destinationLocation != null) 'destinationLocation': destinationLocation,
      if (fromCity != null) 'fromCity': fromCity,
      if (toCity != null) 'toCity': toCity,
      if (fromLocation != null) 'fromLocation': fromLocation,
      if (toLocation != null) 'toLocation': toLocation,
      if (time != null) 'time': time,
      if (availableSeats != null) 'availableSeats': availableSeats,
      if (suggestedPrice != null) 'suggestedPrice': suggestedPrice,
      if (price != null) 'price': price,
      if (finalPrice != null) 'finalPrice': finalPrice,
      if (negotiationPrice != null) 'negotiationPrice': negotiationPrice,
      if (lastNegotiator != null) 'lastNegotiator': lastNegotiator,
      if (errandDetails != null) 'errandDetails': errandDetails,
      if (errandCost != null) 'errandCost': errandCost,
      if (audioUrl != null) 'audioUrl': audioUrl,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}