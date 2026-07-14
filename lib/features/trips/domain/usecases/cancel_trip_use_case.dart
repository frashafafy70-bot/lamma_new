import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class CancelTripUseCase {
  final TripRepository repository;
  CancelTripUseCase(this.repository);

  Future<Either<Failure, void>> call({required String tripId, required bool isDriver}) async {
    return await repository.cancelTrip(tripId: tripId, isDriver: isDriver);
  }
}