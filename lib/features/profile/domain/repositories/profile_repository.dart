import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart'; 
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getUserProfile();
  Future<Either<Failure, Unit>> switchUserRole(String newRole);
  Future<Either<Failure, Unit>> submitRoleRegistration(String role, Map<String, dynamic> profileData);
  Future<Either<Failure, String>> uploadDocument(String role, String docName, File file);
  Future<Either<Failure, Unit>> updateUserProfile({
    required String name,
    required String phone,
    String? nationalId,
    File? newProfileImage,
    required String currentImageUrl,
  });
}