import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class DeleteTripUseCase {
  final TripRepository repository;

  DeleteTripUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId) async {
    return await repository.deleteTrip(tripId);
  }
}
