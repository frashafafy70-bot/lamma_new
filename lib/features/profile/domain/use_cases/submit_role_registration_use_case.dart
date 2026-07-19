import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class SubmitRoleRegistrationUseCase {
  final ProfileRepository repository;

  SubmitRoleRegistrationUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    return await repository.submitRoleRegistration(role, profileData);
  }
}
