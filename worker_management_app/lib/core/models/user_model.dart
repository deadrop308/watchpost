/// Represents the role of a user in the system.
/// Each role has access to different parts of the app.
enum UserRole {
  worker,
  manager,
  admin,
}

/// Converts a string from Firestore into a [UserRole] enum value.
UserRole userRoleFromString(String roleString) {
  switch (roleString) {
    case 'manager':
      return UserRole.manager;
    case 'admin':
      return UserRole.admin;
    case 'worker':
    default:
      return UserRole.worker;
  }
}

/// Converts a [UserRole] enum value into a string for storing in Firestore.
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.manager:
      return 'manager';
    case UserRole.admin:
      return 'admin';
    case UserRole.worker:
      return 'worker';
  }
}

/// Represents a user account in the system.
/// This model is used for workers, managers, and admins.
class UserModel {
  /// The unique Firebase Authentication user ID
  final String userId;

  /// The email address used to log in
  final String emailAddress;

  /// The full name of the user
  final String fullName;

  /// The role of the user, determining app access level
  final UserRole role;

  /// The branch this user belongs to.
  /// Empty for admin users as they belong to the whole company.
  final String branchId;

  /// Whether this user account is active
  final bool isActive;

  /// When this user account was created
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.emailAddress,
    required this.fullName,
    required this.role,
    this.branchId = '',
    required this.isActive,
    required this.createdAt,
  });

  /// Creates a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(Map<String, dynamic> firestoreData, String documentId) {
    return UserModel(
      userId: documentId,
      emailAddress: firestoreData['emailAddress'] as String,
      fullName: firestoreData['fullName'] as String,
      role: userRoleFromString(firestoreData['role'] as String),
      branchId: firestoreData['branchId'] as String? ?? '',
      isActive: firestoreData['isActive'] as bool,
      createdAt: (firestoreData['createdAt'] as dynamic).toDate(),
    );
  }

  /// Converts this [UserModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'emailAddress': emailAddress,
      'fullName': fullName,
      'role': userRoleToString(role),
      'branchId': branchId,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
  /// Two users are considered equal if they share the same [userId].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

