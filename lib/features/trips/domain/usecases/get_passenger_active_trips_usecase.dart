import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../../data/models/trip_model.dart';

class GetPassengerActiveTripsUseCase {
  final TripRepository repository;

  GetPassengerActiveTripsUseCase(this.repository);

  Future<Either<Failure, List<TripModel>>> call({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    return await repository.getPassengerActiveTrips(
      uid: uid,
      limit: limit,
      lastTrip: lastTrip,
    );
  }
}