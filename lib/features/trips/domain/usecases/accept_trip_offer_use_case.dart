import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class AcceptTripOfferUseCase {
  final TripRepository repository;

  AcceptTripOfferUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String tripId,
    required String finalPrice,
    required bool isDriver,
    required String currentUserId,
  }) async {
    return await repository.acceptTripOffer(
      tripId: tripId,
      finalPrice: finalPrice,
      isDriver: isDriver,
      currentUserId: currentUserId,
    );
  }
}
