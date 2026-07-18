import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class SyncDriverLocationUseCase {
  final TripRepository repository;

  SyncDriverLocationUseCase(this.repository);

  // 🟢 الدالة بقت بتاخد lat و lng مباشر
  Future<Either<Failure, void>> call(String tripId, double lat, double lng) async {
    return await repository.syncDriverLocation(tripId, lat, lng);
  }
}