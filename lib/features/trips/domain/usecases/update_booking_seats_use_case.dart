import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class UpdateBookingSeatsUseCase {
  final TripRepository repository;
  UpdateBookingSeatsUseCase(this.repository);

  Future<Either<Failure, void>> call(
      {required String bookingId,
      required int newSeats,
      required DateTime travelDate}) async {
    return await repository.updateBookingSeats(
        bookingId: bookingId, newSeats: newSeats, travelDate: travelDate);
  }
}
