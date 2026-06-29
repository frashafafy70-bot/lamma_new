import '../data/models/family_member_model.dart';

abstract class FamilyState {}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyMember> members;
  FamilyLoaded(this.members);
}

class FamilyMemberFound extends FamilyState {
  final Map<String, dynamic> userData;
  FamilyMemberFound(this.userData);
}

class FamilyError extends FamilyState {
  final String message;
  FamilyError(this.message);
}

class FamilyActionSuccess extends FamilyState {
  final String message;
  FamilyActionSuccess(this.message);
}