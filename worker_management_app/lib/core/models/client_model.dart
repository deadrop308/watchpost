import 'note_entry_model.dart';

/// Represents a client that a branch serves.
/// Each client can have multiple locations.
class ClientModel {
  /// The unique Firestore document ID for this client
  final String clientId;

  /// The display name of the client, e.g. "בנק הפועלים"
  final String clientName;

  /// The branch this client belongs to
  final String branchId;

  /// When this client was created
  final DateTime createdAt;

  /// Whether this client is active.
  /// Soft-deleted clients have isActive set to false.
  final bool isActive;

  /// Timestamped notes about this client, newest first
  final List<NoteEntry> notes;

  const ClientModel({
    required this.clientId,
    required this.clientName,
    required this.branchId,
    required this.createdAt,
    required this.isActive,
    this.notes = const [],
  });

  /// Creates a [ClientModel] from a Firestore document snapshot.
  factory ClientModel.fromFirestore(
      Map<String, dynamic> firestoreData, String documentId) {
    return ClientModel(
      clientId: documentId,
      clientName: firestoreData['clientName'] as String,
      branchId: firestoreData['branchId'] as String,
      createdAt: (firestoreData['createdAt'] as dynamic).toDate(),
      isActive: firestoreData['isActive'] as bool,
      notes: NoteEntry.listFromFirestore(firestoreData['notes']),
    );
  }

  /// Converts this [ClientModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'clientName': clientName,
      'branchId': branchId,
      'createdAt': createdAt,
      'isActive': isActive,
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }

  /// Two clients are considered equal if they share the same [clientId].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel && other.clientId == clientId;
  }

  @override
  int get hashCode => clientId.hashCode;
}