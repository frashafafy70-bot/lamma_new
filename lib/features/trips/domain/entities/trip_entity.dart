class TripEntity {
  final String id;
  final String driverId;
  final String startLocation;
  final String endLocation;
  final DateTime departureDate;
  final String departureTime;
  final int totalSeats;
  final int availableSeats;
  final double seatPrice;
  final String status; // مثال: 'pending', 'active', 'completed', 'cancelled'

  const TripEntity({
    required this.id,
    required this.driverId,
    required this.startLocation,
    required this.endLocation,
    required this.departureDate,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.seatPrice,
    required this.status,
  });

  // إضافة دالة copyWith بتسهل علينا جداً تعديل بيانات الرحلة لاحقاً في الـ UI
  // من غير ما نكسر قاعدة الـ (Immutable)
  TripEntity copyWith({
    String? id,
    String? driverId,
    String? startLocation,
    String? endLocation,
    DateTime? departureDate,
    String? departureTime,
    int? totalSeats,
    int? availableSeats,
    double? seatPrice,
    String? status,
  }) {
    return TripEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      seatPrice: seatPrice ?? this.seatPrice,
      status: status ?? this.status,
    );
  }
}