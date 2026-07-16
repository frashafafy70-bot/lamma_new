import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class SyncDriverLocationUseCase {
  final TripRepository repository;

  SyncDriverLocationUseCase(this.repository);

  Future<Either<Failure, void>> call(String tripId, GeoPoint location) async {
    return await repository.syncDriverLocation(tripId, location.latitude, location.longitude);
  }
}