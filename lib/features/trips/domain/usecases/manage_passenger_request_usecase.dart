import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

class ManagePassengerRequestUseCase {
  final FirebaseFirestore firestore;

  ManagePassengerRequestUseCase(this.firestore);

  Future<Either<dynamic, void>> deleteRequest(String docId) async {
    try {
      await firestore.collection('trips').doc(docId).update({
        'isDeletedForPassenger': true,
      });
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }

  Future<Either<dynamic, void>> acceptOffer(
      String docId, String acceptedPrice) async {
    try {
      await firestore
          .collection('trips')
          .doc(docId)
          .update({'status': 'accepted', 'finalPrice': acceptedPrice});
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }

  Future<Either<dynamic, void>> rejectTrip(String docId) async {
    try {
      await firestore
          .collection('trips')
          .doc(docId)
          .update({'status': 'canceled', 'canceledBy': 'passenger'});
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }

  Future<Either<dynamic, void>> negotiateTrip(
      String docId, String offer, String type) async {
    try {
      await firestore.collection('trips').doc(docId).update({
        'status': 'negotiating',
        'negotiationPrice': offer,
        'negotiationType': type,
        'lastNegotiator': 'passenger'
      });
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}
