import '../repositories/trip_repository.dart';

class GetPassengerActiveOrdersCountUseCase {
  final TripRepository repository;

  GetPassengerActiveOrdersCountUseCase(this.repository);

  Stream<int> call(String uid) {
    return repository.getPassengerActiveOrdersCountStream(uid);
  }
}