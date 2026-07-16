import '../../data/models/trip_model.dart';
import '../repositories/driver_radar_repository.dart';

class GetDriverRadarTripsUseCase {
  final DriverRadarRepository repository;

  GetDriverRadarTripsUseCase(this.repository);

  Future<dynamic> call({required int limit, TripModel? lastTrip}) async {
    return await repository.getPaginatedRadarTrips(limit: limit, lastTrip: lastTrip);
  }
}