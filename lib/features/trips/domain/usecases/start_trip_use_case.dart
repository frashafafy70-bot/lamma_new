import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class StartTripUseCase {
  final TripRepository repository;

  StartTripUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId) async {
    return await repository.startTrip(tripId);
  }
}