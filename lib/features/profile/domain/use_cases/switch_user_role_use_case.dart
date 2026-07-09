import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class SwitchUserRoleUseCase {
  final ProfileRepository repository;

  SwitchUserRoleUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String newRole) async {
    return await repository.switchUserRole(newRole);
  }
}