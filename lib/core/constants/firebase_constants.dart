class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String notificationsCollection = 'notifications';

  // User Fields
  static const String activeRoleField = 'activeRole';
  static const String rolesField = 'roles';
  static const String profilesField = 'profiles';

  // Roles Keys
  static const String roleCustomer = 'customer';
  static const String roleDriver = 'driver';
  static const String roleLawyer = 'lawyer';
  static const String roleDoctor = 'doctor';
  static const String roleNurse = 'nurse';

  // Trip Statuses
  static const String statusPending = 'pending';
  static const String statusNegotiating = 'negotiating';
  static const String statusAccepted = 'accepted';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Trip Fields
  static const String fieldStatus = 'status';
  static const String fieldLastNegotiator = 'lastNegotiator';
  static const String fieldNegotiationPrice = 'negotiationPrice';
  static const String fieldFinalPrice = 'finalPrice';
}