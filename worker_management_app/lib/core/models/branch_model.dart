/// Represents a company branch that workers and managers are assigned to.
/// Branches are created and managed by the admin.
class BranchModel {
  /// The unique Firestore document ID for this branch
  final String branchId;

  /// The display name of the branch, e.g. "Microsoft Office Tel Aviv"
  final String branchName;

  /// When this branch was created
  final DateTime createdAt;

  /// Whether this branch is active.
  /// Inactive branches are hidden from the admin dropdown.
  final bool isActive;

  const BranchModel({
    required this.branchId,
    required this.branchName,
    required this.createdAt,
    required this.isActive,
  });

  /// Creates a [BranchModel] from a Firestore document snapshot.
  factory BranchModel.fromFirestore(
      Map<String, dynamic> firestoreData, String documentId) {
    return BranchModel(
      branchId: documentId,
      branchName: firestoreData['branchName'] as String,
      createdAt: (firestoreData['createdAt'] as dynamic).toDate(),
      isActive: firestoreData['isActive'] as bool,
    );
  }

  /// Converts this [BranchModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'branchName': branchName,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}