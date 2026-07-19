import 'package:cloud_firestore/cloud_firestore.dart';

// 🟢 تأكد من صحة مسارات الاستيراد بناءً على هيكل ملفاتك
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../../../core/entities/location_coordinates.dart';

class TripModel extends TripEntity {
  const TripModel({
    super.id,
    required super.isDriverPost,
    super.driverId,
    super.driverName,
    super.passengerId,
    super.passengerName,
    super.tripCategory,
    super.vehicleType,
    super.pickup,
    super.destination,
    super.pickupLocation,
    super.destinationLocation,
    super.fromCity,
    super.toCity,
    super.fromLocation,
    super.toLocation,
    super.time,
    super.travelDate,
    super.tripType,
    super.availableSeats,
    super.suggestedPrice,
    super.price,
    super.seatPrice,
    super.fullCarPrice,
    super.finalPrice,
    super.negotiationPrice,
    super.lastNegotiator,
    super.errandDetails,
    super.errandCost,
    super.audioUrl,
    required super.status,
    super.createdAt,
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

    bool parseBool(dynamic data) {
      if (data == null) return false;
      if (data is bool) return data;
      if (data is String) return data.toLowerCase() == 'true';
      return false;
    }

    // 🟢 دالة لتحويل أرقام Firebase (التي قد تأتي String أو int) إلى double بأمان
    double? parseDouble(dynamic data) {
      if (data == null) return null;
      if (data is double) return data;
      if (data is int) return data.toDouble();
      if (data is String) return double.tryParse(data);
      return null;
    }

    // 🟢 دالة لتحويل المقاعد إلى int بأمان
    int? parseInt(dynamic data) {
      if (data == null) return null;
      if (data is int) return data;
      if (data is double) return data.toInt();
      if (data is String) return int.tryParse(data);
      return null;
    }

    // 🟢 الأهم: تحويل GeoPoint الخاص بـ Firebase إلى الكلاس النقي الخاص بنا
    LocationCoordinates? parseLocation(dynamic data) {
      if (data is GeoPoint) {
        return LocationCoordinates(
          latitude: data.latitude,
          longitude: data.longitude,
        );
      }
      return null;
    }

    return TripModel(
      id: documentId,
      isDriverPost: parseBool(map['isDriverPost']),
      driverId: map['driverId']?.toString(),
      driverName: map['driverName']?.toString(),
      passengerId: map['passengerId']?.toString(),
      passengerName: map['passengerName']?.toString(),
      tripCategory: map['tripCategory']?.toString(),
      vehicleType: map['vehicleType']?.toString(),
      pickup: map['pickup']?.toString(),
      destination: map['destination']?.toString(),

      // استخدام دوال التحويل الجديدة للإحداثيات
      pickupLocation: parseLocation(map['pickupLocation']),
      destinationLocation: parseLocation(map['destinationLocation']),

      fromCity: map['fromCity']?.toString(),
      toCity: map['toCity']?.toString(),

      // استخدام دوال التحويل الجديدة للإحداثيات
      fromLocation: parseLocation(map['fromLocation']),
      toLocation: parseLocation(map['toLocation']),

      time: map['time']?.toString(),
      travelDate: parseDate(map['travelDate']),
      tripType: map['tripType']?.toString(),

      // استخدام دوال التحويل للأرقام
      availableSeats: parseInt(map['availableSeats']),
      suggestedPrice: parseDouble(map['suggestedPrice']),
      price: parseDouble(map['price']),
      seatPrice: parseDouble(map['seatPrice']),
      fullCarPrice: parseDouble(map['fullCarPrice']),
      finalPrice: parseDouble(map['finalPrice']),
      negotiationPrice: parseDouble(map['negotiationPrice']),
      errandCost: parseDouble(map['errandCost']),

      lastNegotiator: map['lastNegotiator']?.toString(),
      errandDetails: map['errandDetails']?.toString(),
      audioUrl: map['audioUrl']?.toString(),

      // 🟢 تحويل النص القادم من قاعدة البيانات إلى Enum القوي بتاعنا
      status: TripStatus.fromString(map['status']?.toString() ?? ''),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    // 🟢 دالة عكسية لتحويل الكلاس النقي إلى GeoPoint قبل الإرسال لـ Firebase
    GeoPoint? toGeoPoint(LocationCoordinates? loc) {
      if (loc == null) return null;
      return GeoPoint(loc.latitude, loc.longitude);
    }

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

      // تحويل الإحداثيات لـ GeoPoint
      if (pickupLocation != null) 'pickupLocation': toGeoPoint(pickupLocation),
      if (destinationLocation != null)
        'destinationLocation': toGeoPoint(destinationLocation),

      if (fromCity != null) 'fromCity': fromCity,
      if (toCity != null) 'toCity': toCity,

      // تحويل الإحداثيات لـ GeoPoint
      if (fromLocation != null) 'fromLocation': toGeoPoint(fromLocation),
      if (toLocation != null) 'toLocation': toGeoPoint(toLocation),

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

      // 🟢 سحب القيمة النصية من الـ Enum لإرسالها لقاعدة البيانات
      'status': status.value,

      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
