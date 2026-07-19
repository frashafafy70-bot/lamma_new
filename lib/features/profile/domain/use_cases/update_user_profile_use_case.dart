import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String name,
    required String phone,
    String? nationalId,
    File? newProfileImage,
    required String currentImageUrl,
  }) async {
    return await repository.updateUserProfile(
      name: name,
      phone: phone,
      nationalId: nationalId,
      newProfileImage: newProfileImage,
      currentImageUrl: currentImageUrl,
    );
  }
}
