class FamilyMember {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? activeTripId;
  final bool isTrackingEnabled;

  FamilyMember({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.activeTripId,
    this.isTrackingEnabled = true,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map, String documentId) {
    return FamilyMember(
      uid: documentId,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      activeTripId: map['activeTripId'],
      isTrackingEnabled: map['isTrackingEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'activeTripId': activeTripId,
      'isTrackingEnabled': isTrackingEnabled,
    };
  }

  FamilyMember copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? activeTripId,
    bool? isTrackingEnabled,
  }) {
    return FamilyMember(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      activeTripId: activeTripId ?? this.activeTripId,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
    );
  }
}