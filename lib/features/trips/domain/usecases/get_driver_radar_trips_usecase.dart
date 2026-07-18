import '../../data/models/trip_model.dart';
import '../repositories/driver_radar_repository.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
class GetDriverRadarTripsUseCase {
  final DriverRadarRepository repository;

  GetDriverRadarTripsUseCase(this.repository);

  Future<dynamic> call({required int limit, TripEntity? lastTrip}) async {
    return await repository.getPaginatedRadarTrips(limit: limit, lastTrip: lastTrip);
  }
}