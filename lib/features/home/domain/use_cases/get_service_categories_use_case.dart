import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_category_entity.dart';
import '../repositories/home_repository.dart';

class GetServiceCategoriesUseCase {
  final HomeRepository repository;

  GetServiceCategoriesUseCase(this.repository);

  Future<Either<Failure, List<ServiceCategoryEntity>>> call() async {
    return await repository.getServiceCategories();
  }
}