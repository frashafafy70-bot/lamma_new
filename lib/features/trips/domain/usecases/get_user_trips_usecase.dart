import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetUserTripsUseCase {
  final TripRepository repository;

  GetUserTripsUseCase(this.repository);

  Stream<List<TripEntity>> call(String userId) {
    return repository.getUserTrips(userId);
  }
}