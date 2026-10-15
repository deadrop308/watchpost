import 'close_form_model.dart';

/// Represents a type of operation that a worker can select when opening a call.
/// Operation types are managed by managers and are branch-specific.
class OperationTypeModel {
  /// The unique Firestore document ID for this operation type
  final String operationTypeId;

  /// The display name of the operation type, e.g. "טיפול מונע"
  final String operationTypeName;

  /// The branch this operation type belongs to.
  /// Workers only see operation types from their own branch.
  final String branchId;

  /// When this operation type was created
  final DateTime createdAt;

  /// Whether this operation type is active and visible to workers.
  /// Soft-deleted operation types have isActive set to false.
  final bool isActive;

  /// The close-call form workers fill in for this operation type
  final CloseFormConfig closeForm;

  const OperationTypeModel({
    required this.operationTypeId,
    required this.operationTypeName,
    required this.branchId,
    required this.createdAt,
    required this.isActive,
    this.closeForm = CloseFormConfig.defaultConfig,
  });

  /// Creates an [OperationTypeModel] from a Firestore document snapshot.
  factory OperationTypeModel.fromFirestore(
      Map<String, dynamic> firestoreData, String documentId) {
    return OperationTypeModel(
      operationTypeId: documentId,
      operationTypeName: firestoreData['operationTypeName'] as String,
      branchId: firestoreData['branchId'] as String,
      createdAt: (firestoreData['createdAt'] as dynamic).toDate(),
      isActive: firestoreData['isActive'] as bool,
      closeForm: CloseFormConfig.fromMap(firestoreData['closeForm']),
    );
  }

  /// Converts this [OperationTypeModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'operationTypeName': operationTypeName,
      'branchId': branchId,
      'createdAt': createdAt,
      'isActive': isActive,
      'closeForm': closeForm.toMap(),
    };
  }

  /// Two operation types are considered equal if they share the same [operationTypeId].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperationTypeModel &&
        other.operationTypeId == operationTypeId;
  }

  @override
  int get hashCode => operationTypeId.hashCode;
}