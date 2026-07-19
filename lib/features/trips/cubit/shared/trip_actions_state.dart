abstract class TripActionsState {}

class TripActionsInitial extends TripActionsState {}

class TripActionsLoading extends TripActionsState {}

class TripActionsSuccess extends TripActionsState {
  final String action;
  final String message;

  TripActionsSuccess({required this.action, required this.message});
}

class TripActionsError extends TripActionsState {
  final String message;

  TripActionsError(this.message);
}
