import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';
import '../entities/trip_entity.dart'; // 🟢 استدعاء الـ Entity بدل الـ Model

class GetDriverActiveTripsUseCase {
  final TripRepository repository;

  GetDriverActiveTripsUseCase(this.repository);

  // 🟢 تم إصلاح القوس الناقص هنا وإضافة List<TripEntity>
  Future<Either<Failure, List<TripEntity>>> call({
    required String uid,
    required int limit,
    TripEntity? lastTrip, // 🟢 تم التعديل
  }) async {
    return await repository.getDriverActiveTrips(
      uid: uid,
      limit: limit,
      lastTrip: lastTrip,
    );
  }
}