import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class CompleteTripUseCase {
  final TripRepository repository;

  CompleteTripUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId) async {
    return await repository.completeTrip(tripId);
  }
}