import '../../data/models/trip_model.dart';
import '../repositories/trip_repository.dart';
import 'package:lamma_new/features/trips/domain/entities/trip_entity.dart';
class GetAvailableTravelsUseCase {
  final TripRepository repository;

  GetAvailableTravelsUseCase(this.repository);

  Future<dynamic> call({required int limit, TripEntity? lastTrip}) async {
    return await repository.getAvailableTravels(limit: limit, lastTrip: lastTrip);
  }
}