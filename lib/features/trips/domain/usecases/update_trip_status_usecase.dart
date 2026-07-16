import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class UpdateTripStatusUseCase {
  final TripRepository repository;
  UpdateTripStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId, String status) async {
    return await repository.updateTripStatus(tripId, status);
  }
}