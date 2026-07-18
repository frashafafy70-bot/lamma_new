import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../entities/trip_entity.dart'; // 🟢 استدعاء الـ Entity بدل الـ Model

class GetPassengerActiveTripsUseCase {
  final TripRepository repository;

  GetPassengerActiveTripsUseCase(this.repository);

  Future<Either<Failure, List<TripEntity>>> call({
    required String uid,
    required int limit,
    TripEntity? lastTrip, // 🟢 تم التعديل
  }) async {
    return await repository.getPassengerActiveTrips(
      uid: uid,
      limit: limit,
      lastTrip: lastTrip,
    );
  }
}