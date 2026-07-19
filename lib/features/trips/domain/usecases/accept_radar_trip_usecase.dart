import 'package:dartz/dartz.dart';
import '../repositories/driver_radar_repository.dart';

class AcceptRadarTripUseCase {
  final DriverRadarRepository repository;

  AcceptRadarTripUseCase(this.repository);

  Future<Either<dynamic, void>> call(String tripId,
      {String? negotiatedPrice}) async {
    try {
      await repository.acceptTripSecurely(tripId, negotiatedPrice);
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}
