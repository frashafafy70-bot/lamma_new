import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';
import '../repositories/trip_repository.dart';

class PublishTravelTripUseCase {
  final TripRepository repository;

  PublishTravelTripUseCase(this.repository);

  Future<Either<Failure, void>> call(TripModel trip) async {
    return await repository.publishTravelTrip(trip);
  }
}