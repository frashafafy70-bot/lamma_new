class OrderSummaryEntity {
  final String orderId;
  final String serviceType;
  final String status;
  final DateTime createdAt;
  final double? price;

  OrderSummaryEntity({
    required this.orderId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.price,
  });
}
