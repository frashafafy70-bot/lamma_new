import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/trip_repository.dart';

class SubmitNegotiationUseCase {
  final TripRepository repository;
  SubmitNegotiationUseCase(this.repository);

  Future<Either<Failure, void>> call(
      {required String docId,
      required double offerPrice,
      required bool isDriver}) async {
    return await repository.submitNegotiation(
        docId: docId, offerPrice: offerPrice, isDriver: isDriver);
  }
}
