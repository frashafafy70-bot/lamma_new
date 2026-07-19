import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class AcceptPassengerBookingUseCase {
  final TripRepository repository;
  AcceptPassengerBookingUseCase(this.repository);

  Future<Either<Failure, void>> call(
      {required String bookingId,
      required String tripId,
      required int seatsToDeduct}) async {
    return await repository.acceptPassengerBooking(
        bookingId: bookingId, tripId: tripId, seatsToDeduct: seatsToDeduct);
  }
}
