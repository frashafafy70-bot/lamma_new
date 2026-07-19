import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class CheckHasActiveTripUseCase {
  final TripRepository repository;
  CheckHasActiveTripUseCase(this.repository);

  Future<Either<Failure, bool>> call(String driverId) async {
    return await repository.checkHasActiveTrip(driverId);
  }
}
