import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_summary_entity.dart';
import '../repositories/home_repository.dart';

class GetActiveOrdersSummaryUseCase {
  final HomeRepository repository;

  GetActiveOrdersSummaryUseCase(this.repository);

  Future<Either<Failure, List<OrderSummaryEntity>>> call() async {
    return await repository.getActiveOrdersSummary();
  }
}