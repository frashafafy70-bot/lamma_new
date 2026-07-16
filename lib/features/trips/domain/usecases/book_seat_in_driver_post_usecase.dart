import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class BookSeatInDriverPostUseCase {
  final TripRepository repository;

  BookSeatInDriverPostUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String tripId,
    required String driverId,
    required String passengerId,
    required int seatsToBook,
  }) async {
    return await repository.bookSeatInDriverPost(
      tripId: tripId,
      driverId: driverId,
      passengerId: passengerId,
      seatsToBook: seatsToBook,
    );
  }
}
