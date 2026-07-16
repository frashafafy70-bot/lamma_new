import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetUserDataUseCase {
  final AuthRepository repository;

  GetUserDataUseCase(this.repository);

  Future<Either<String, UserEntity?>> call(String uid) async {
    return await repository.getUserData(uid);
  }
}