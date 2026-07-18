import '../../../../core/entities/location_coordinates.dart';

enum TripStatus {
  pending('pending'),
  available('available'),
  negotiating('negotiating'),
  accepted('accepted'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const TripStatus(this.value);

  // دالة للتحويل من نص (قادم من الداتا بيز) إلى Enum
  static TripStatus fromString(String status) {
    return TripStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => TripStatus.pending, // القيمة الافتراضية
    );
  }
}