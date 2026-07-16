import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetTripsUseCase {
  final TripRepository repository;

  GetTripsUseCase(this.repository);

  Stream<List<TripEntity>> call() {
    return repository.getTrips();
  }
}