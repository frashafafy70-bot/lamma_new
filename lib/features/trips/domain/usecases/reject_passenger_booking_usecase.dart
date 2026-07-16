import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class RejectPassengerBookingUseCase {
  final TripRepository repository;
  RejectPassengerBookingUseCase(this.repository);

  Future<Either<Failure, void>> call({required String bookingId, required String tripId, required String passengerId}) async {
    return await repository.rejectPassengerBooking(bookingId: bookingId, tripId: tripId, passengerId: passengerId);
  }
}