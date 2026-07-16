import 'package:dartz/dartz.dart';
import '../repositories/driver_radar_repository.dart';

class NegotiateRadarTripUseCase {
  final DriverRadarRepository repository;

  NegotiateRadarTripUseCase(this.repository);

  Future<Either<dynamic, void>> call(String tripId, String offer) async {
    try {
      await repository.negotiateTrip(tripId, offer);
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}