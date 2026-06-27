import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PassengerMyRequestsState {}

class PassengerMyRequestsInitial extends PassengerMyRequestsState {}

class PassengerMyRequestsLoading extends PassengerMyRequestsState {}

class PassengerMyRequestsLoaded extends PassengerMyRequestsState {
  final List<QueryDocumentSnapshot> requests;
  PassengerMyRequestsLoaded(this.requests);
}

class PassengerMyRequestsError extends PassengerMyRequestsState {
  final String message;
  PassengerMyRequestsError(this.message);
}