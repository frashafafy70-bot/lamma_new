import '../repositories/home_repository.dart';

class GetRadarBadgeUseCase {
  final HomeRepository repository;
  GetRadarBadgeUseCase(this.repository);
  Stream<int> call(String currentUserId) =>
      repository.getRadarBadgeCountStream(currentUserId);
}

class GetActiveTripsBadgeUseCase {
  final HomeRepository repository;
  GetActiveTripsBadgeUseCase(this.repository);
  Stream<int> call(String currentUserId) =>
      repository.getActiveTripsBadgeCountStream(currentUserId);
}

class GetClientRequestsBadgeUseCase {
  final HomeRepository repository;
  GetClientRequestsBadgeUseCase(this.repository);
  Stream<int> call(String currentUserId) =>
      repository.getClientRequestsBadgeCountStream(currentUserId);
}
