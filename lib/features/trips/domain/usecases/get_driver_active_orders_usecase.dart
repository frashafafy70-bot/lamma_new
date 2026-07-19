import '../repositories/trip_repository.dart';

class GetDriverActiveOrdersCountUseCase {
  final TripRepository repository;

  GetDriverActiveOrdersCountUseCase(this.repository);

  Stream<int> call(String uid) {
    return repository.getDriverActiveOrdersCountStream(uid);
  }
}
