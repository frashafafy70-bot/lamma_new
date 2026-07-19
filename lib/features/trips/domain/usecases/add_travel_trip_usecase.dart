import 'package:lamma_new/features/trips/data/models/trip_model.dart';
import '../repositories/trip_repository.dart';

class AddTravelTripUseCase {
  final TripRepository repository;

  AddTravelTripUseCase(this.repository);

  Future<void> call(TripEntity trip) {
    return repository.addTravelTrip(trip);
  }
}
