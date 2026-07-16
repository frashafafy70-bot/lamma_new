import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../entities/trip_entity.dart';

class UpdateTripUseCase {
  final TripRepository repository;

  UpdateTripUseCase(this.repository);

  Future<Either<Failure, void>> call(TripEntity trip) async {
    return await repository.updateTrip(trip);
  }
}