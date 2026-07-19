import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UploadDocumentUseCase {
  final ProfileRepository repository;

  UploadDocumentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String role,
    required String docName,
    required File file,
  }) async {
    return await repository.uploadDocument(role, docName, file);
  }
}
