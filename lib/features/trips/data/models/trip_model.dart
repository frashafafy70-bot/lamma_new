import 'package:cloud_firestore/cloud_firestore.dart';

// 🟢 كلاس مخصص لحالات الرحلة عشان نتجنب أي خطأ إملائي في كتابة الحالة
class TripStatus {
  static const String pending = 'pending';         // طلب جديد
  static const String available = 'available';     // رحلة سفر منشورة ومتاحة
  static const String negotiating = 'negotiating'; // قيد التفاوض
  static const String accepted = 'accepted';       // تم القبول
  static const String inProgress = 'in_progress';  // الرحلة بدأت وشغالة
  static const String completed = 'completed';     // الرحلة انتهت
  static const String cancelled = 'cancelled';     // الرحلة اتلغت
}

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

  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    // 🛡️ دوال مساعدة لحماية التحويل ومنع انهيار التطبيق 🛡️
    
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is Timestamp) return data.toDate();
      if (data is String) return DateTime.tryParse(data);
      if (data is int) return DateTime.fromMillisecondsSinceEpoch(data);
      return null;
    }

    GeoPoint? parseGeoPoint(dynamic data) {
      if (data is GeoPoint) return data;
      return null;
    }

    bool parseBool(dynamic data) {
      if (data == null) return false;
      if (data is bool) return data;
      if (data is String) return data.toLowerCase() == 'true';
      return false;
    }

    return TripModel(
      id: documentId,
      isDriverPost: parseBool(map['isDriverPost']),
      // استخدام ?.toString() يضمن تحويل الأرقام لنصوص بأمان إذا تم حفظها كأرقام في قاعدة البيانات
      driverId: map['driverId']?.toString(),
      driverName: map['driverName']?.toString(),
      passengerId: map['passengerId']?.toString(),
      passengerName: map['passengerName']?.toString(),
      tripCategory: map['tripCategory']?.toString(),
      vehicleType: map['vehicleType']?.toString(),
      pickup: map['pickup']?.toString(),
      destination: map['destination']?.toString(),
      pickupLocation: parseGeoPoint(map['pickupLocation']),
      destinationLocation: parseGeoPoint(map['destinationLocation']),
      fromCity: map['fromCity']?.toString(),
      toCity: map['toCity']?.toString(),
      fromLocation: parseGeoPoint(map['fromLocation']),
      toLocation: parseGeoPoint(map['toLocation']),
      time: map['time']?.toString(),
      travelDate: parseDate(map['travelDate']), 
      tripType: map['tripType']?.toString(), 
      availableSeats: map['availableSeats']?.toString(),
      suggestedPrice: map['suggestedPrice']?.toString(),
      price: map['price']?.toString(),
      seatPrice: map['seatPrice']?.toString(), 
      fullCarPrice: map['fullCarPrice']?.toString(), 
      finalPrice: map['finalPrice']?.toString(),
      negotiationPrice: map['negotiationPrice']?.toString(),
      lastNegotiator: map['lastNegotiator']?.toString(),
      errandDetails: map['errandDetails']?.toString(),
      errandCost: map['errandCost']?.toString(),
      audioUrl: map['audioUrl']?.toString(),
      status: map['status']?.toString() ?? TripStatus.pending,
      createdAt: parseDate(map['createdAt']),
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
      if (travelDate != null) 'travelDate': Timestamp.fromDate(travelDate!), 
      if (tripType != null) 'tripType': tripType, 
      if (availableSeats != null) 'availableSeats': availableSeats,
      if (suggestedPrice != null) 'suggestedPrice': suggestedPrice,
      if (price != null) 'price': price,
      if (seatPrice != null) 'seatPrice': seatPrice, 
      if (fullCarPrice != null) 'fullCarPrice': fullCarPrice, 
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