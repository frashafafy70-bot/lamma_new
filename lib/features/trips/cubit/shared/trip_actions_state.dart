abstract class TripActionsState {}

class TripActionsInitial extends TripActionsState {}

class TripActionsLoading extends TripActionsState {}

class TripActionsSuccess extends TripActionsState {
  final String action; // عشان نعرف الأكشن اللي نجح (accept, reject, etc)
  final String message;
  TripActionsSuccess({required this.action, required this.message});
}

class TripActionsError extends TripActionsState {
  final String error;
  TripActionsError(this.error);
}