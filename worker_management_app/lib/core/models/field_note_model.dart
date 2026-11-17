import 'package:cloud_firestore/cloud_firestore.dart';

/// A short note a technician leaves on a machine (location) for the next
/// technician, e.g. "Replaced the belt, the roller is worn".
/// Shown in the Diary for a limited time (default 7 days), then deleted
/// automatically by a Firestore TTL policy on [expiresAt].
/// Notes are never edited; the author or a manager can delete them.
class FieldNoteModel {
  /// The unique Firestore document ID for this note
  final String noteId;

  /// The branch the machine belongs to (everyone in the branch can read it)
  final String branchId;

  /// The business the machine belongs to, copied for display
  final String clientId;
  final String clientName;

  /// The machine (location) the note is about, copied for display
  final String locationId;
  final String locationName;

  /// The note itself
  final String text;

  /// Who wrote the note, copied for display
  final String authorId;
  final String authorName;

  /// When the note was written (set by the server)
  final DateTime createdAt;

  /// When the note disappears from the Diary and gets deleted
  final DateTime expiresAt;

  /// The call the note was written from, if any
  final String? callId;

  /// The operation of that call, e.g. "טיפול מונע", for context
  final String? operationName;

  /// Longest note allowed, matched by the Firestore rules
  static const int maxTextLength = 1000;

  const FieldNoteModel({
    required this.noteId,
    required this.branchId,
    required this.clientId,
    required this.clientName,
    required this.locationId,
    required this.locationName,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.expiresAt,
    this.callId,
    this.operationName,
  });

  /// True once the note's time is up. The TTL deletion can lag by up to a
  /// day, so the app hides expired notes itself.
  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  /// Creates a [FieldNoteModel] from a Firestore document snapshot.
  /// createdAt can briefly be null right after writing (the server
  /// timestamp is still pending), so it falls back to now.
  factory FieldNoteModel.fromFirestore(
    Map<String, dynamic> firestoreData,
    String documentId,
  ) {
    return FieldNoteModel(
      noteId: documentId,
      branchId: firestoreData['branchId'] as String,
      clientId: firestoreData['clientId'] as String? ?? '',
      clientName: firestoreData['clientName'] as String? ?? '',
      locationId: firestoreData['locationId'] as String,
      locationName: firestoreData['locationName'] as String? ?? '',
      text: firestoreData['text'] as String? ?? '',
      authorId: firestoreData['authorId'] as String,
      authorName: firestoreData['authorName'] as String? ?? '',
      createdAt:
          (firestoreData['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      expiresAt: (firestoreData['expiresAt'] as Timestamp).toDate(),
      callId: firestoreData['callId'] as String?,
      operationName: firestoreData['operationName'] as String?,
    );
  }

  /// Converts this note into a map for creating it in Firestore.
  /// createdAt is always the server time (the rules require it).
  Map<String, dynamic> toFirestoreForCreate() {
    return {
      'branchId': branchId,
      'clientId': clientId,
      'clientName': clientName,
      'locationId': locationId,
      'locationName': locationName,
      'text': text,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'callId': callId,
      'operationName': operationName,
    };
  }

  /// Two notes are considered equal if they share the same [noteId].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldNoteModel && other.noteId == noteId;
  }

  @override
  int get hashCode => noteId.hashCode;
}
