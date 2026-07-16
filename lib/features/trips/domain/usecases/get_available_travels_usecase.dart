import '../../data/models/trip_model.dart';
import '../repositories/trip_repository.dart';

class GetAvailableTravelsUseCase {
  final TripRepository repository;

  GetAvailableTravelsUseCase(this.repository);

  Future<dynamic> call({required int limit, TripModel? lastTrip}) async {
    return await repository.getAvailableTravels(limit: limit, lastTrip: lastTrip);
  }
}