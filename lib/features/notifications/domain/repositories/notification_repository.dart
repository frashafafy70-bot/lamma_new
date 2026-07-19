import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  // هنرجع Stream بيحتوي على Either عشان نهندل الأخطاء جوه الـ Stream نفسه!
  Stream<Either<Failure, List<NotificationEntity>>> getNotificationsStream(
      String userId);
}
