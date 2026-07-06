import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetUserDataUseCase {
  final AuthRepository repository;

  GetUserDataUseCase(this.repository);

  Future<UserEntity?> call(String uid) {
    return repository.getUserData(uid);
  }
}