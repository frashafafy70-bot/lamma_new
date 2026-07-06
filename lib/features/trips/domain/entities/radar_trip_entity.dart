class RadarTripEntity {
  final String id;
  final bool isDriverPost;
  final String status;
  final String? driverId;
  final String? price;
  final String? negotiationPrice;

  RadarTripEntity({
    required this.id,
    required this.isDriverPost,
    required this.status,
    this.driverId,
    this.price,
    this.negotiationPrice,
  });
}