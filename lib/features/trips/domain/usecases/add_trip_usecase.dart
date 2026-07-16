import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../entities/trip_entity.dart';

class AddTripUseCase {
  final TripRepository repository;

  AddTripUseCase(this.repository);

  Future<Either<Failure, void>> call(TripEntity trip) async {
    return await repository.addTrip(trip);
  }
}