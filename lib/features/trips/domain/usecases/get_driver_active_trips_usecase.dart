import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../../data/models/trip_model.dart';

class GetDriverActiveTripsUseCase {
  final TripRepository repository;

  GetDriverActiveTripsUseCase(this.repository);

  Future<Either<Failure, List<TripModel>>> call({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    return await repository.getDriverActiveTrips(
      uid: uid,
      limit: limit,
      lastTrip: lastTrip,
    );
  }
}