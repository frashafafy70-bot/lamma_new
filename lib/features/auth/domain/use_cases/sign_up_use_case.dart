import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return await repository.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }
}