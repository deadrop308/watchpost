/// A single timestamped note attached to a client or a location.
/// Notes are stored as a list inside the client/location document.
class NoteEntry {
  /// Unique ID for this note, used to delete a specific entry
  final String noteId;

  /// The note content, e.g. "Machine moved to Maminet 5"
  final String text;

  /// When the note was written
  final DateTime createdAt;

  /// Full name of the manager who wrote the note
  final String authorName;

  const NoteEntry({
    required this.noteId,
    required this.text,
    required this.createdAt,
    required this.authorName,
  });

  /// Creates a [NoteEntry] from a map stored in Firestore.
  factory NoteEntry.fromMap(Map<dynamic, dynamic> map) {
    final dynamic rawCreatedAt = map['createdAt'];
    return NoteEntry(
      noteId: map['noteId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: rawCreatedAt != null
          ? (rawCreatedAt as dynamic).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      authorName: map['authorName'] as String? ?? '',
    );
  }

  /// Converts this [NoteEntry] into a map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'text': text,
      'createdAt': createdAt,
      'authorName': authorName,
    };
  }

  /// Parses the raw 'notes' field from a Firestore document.
  /// Returns an empty list for documents created before notes existed.
  /// Sorted newest first.
  static List<NoteEntry> listFromFirestore(dynamic rawNotes) {
    if (rawNotes is! List) return [];
    final List<NoteEntry> parsedNotes = rawNotes
        .whereType<Map>()
        .map((noteMap) => NoteEntry.fromMap(noteMap))
        .toList();
    parsedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return parsedNotes;
  }
}