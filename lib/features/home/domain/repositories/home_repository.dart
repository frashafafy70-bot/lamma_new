import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_category_entity.dart';
import '../entities/order_summary_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories();
  Future<Either<Failure, List<OrderSummaryEntity>>> getActiveOrdersSummary();
}