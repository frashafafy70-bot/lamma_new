import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class CancelPassengerBookingUseCase {
  final TripRepository repository;
  CancelPassengerBookingUseCase(this.repository);

  Future<Either<Failure, void>> call(
      {required String bookingId,
      required String tripId,
      required String passengerId,
      required int seatsToReturn,
      required bool wasAccepted}) async {
    return await repository.cancelPassengerBooking(
        bookingId: bookingId,
        tripId: tripId,
        passengerId: passengerId,
        seatsToReturn: seatsToReturn,
        wasAccepted: wasAccepted);
  }
}
