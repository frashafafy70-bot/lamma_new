import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_category_entity.dart';
import '../entities/order_summary_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories();
  Future<Either<Failure, List<OrderSummaryEntity>>> getActiveOrdersSummary();
  
  // 🟢 العقود الجديدة الخاصة بالبادجات (ترجع أرقام صافية بدون أي تفاصيل عن الفايربيز)
  Stream<int> getRadarBadgeCountStream(String currentUserId);
  Stream<int> getActiveTripsBadgeCountStream(String currentUserId);
  Stream<int> getClientRequestsBadgeCountStream(String currentUserId);
}