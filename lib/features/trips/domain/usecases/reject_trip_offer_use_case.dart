import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class RejectTripOfferUseCase {
  final TripRepository repository;

  RejectTripOfferUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId) async {
    return await repository.rejectTripOffer(tripId: tripId);
  }
}
