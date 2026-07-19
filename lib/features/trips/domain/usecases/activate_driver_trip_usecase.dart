import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class ActivateDriverTripUseCase {
  final TripRepository repository;
  ActivateDriverTripUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId, String driverId) async {
    return await repository.activateDriverTripFunction(tripId, driverId);
  }
}
