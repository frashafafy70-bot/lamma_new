import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class SubmitTripRatingUseCase {
  final TripRepository repository;

  SubmitTripRatingUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String tripId,
    required double rating,
    required String comment,
  }) async {
    return await repository.submitTripRating(
      tripId: tripId,
      rating: rating,
      comment: comment,
    );
  }
}