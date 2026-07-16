import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/trip_model.dart';
import '../repositories/trip_repository.dart';

class GetDriverHistoryTripsUseCase {
  final TripRepository repository;

  GetDriverHistoryTripsUseCase(this.repository);

  Future<Either<Failure, List<TripModel>>> call({
    required String uid,
    required int limit,
    TripModel? lastTrip,
  }) async {
    return await repository.getDriverHistoryTrips(
      uid: uid,
      limit: limit,
      lastTrip: lastTrip,
    );
  }
}