import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Stream<Either<Failure, List<NotificationEntity>>> call(String userId) {
    return repository.getNotificationsStream(userId);
  }
}
