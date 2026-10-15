import 'note_entry_model.dart';

/// Represents a work location that workers can select when opening a call.
/// Locations are managed by managers and are branch-specific.
class LocationModel {
  /// The unique Firestore document ID for this location
  final String locationId;

  /// The display name of the location, e.g. "בנק הפועלים, ממיינט 7"
  final String locationName;

  /// The branch this location belongs to.
  /// Workers only see locations from their own branch.
  final String branchId;

  /// When this location was created
  final DateTime createdAt;

  /// Whether this location is active and visible to workers.
  /// Soft-deleted locations have isActive set to false.
  /// This preserves historical call data while hiding the location
  /// from the worker dropdown.
  final bool isActive;

  /// The street address of this location, e.g. "בלפור 97, בת ים"
  /// Used for display and navigation purposes.
  final String address;

  /// The GPS coordinates of this location as a GeoPoint.
  /// Used for opening navigation apps with the exact location.
  final double latitude;
  final double longitude;

  /// The ID of the client this location belongs to
  final String clientId;

  /// The name of the client, stored directly for easy display
  final String clientName;

  /// Timestamped notes about this location, newest first
  /// (e.g. machine history, access instructions)
  final List<NoteEntry> notes;

  const LocationModel({
    required this.locationId,
    required this.locationName,
    required this.branchId,
    required this.createdAt,
    required this.isActive,
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.clientId = '',
    this.clientName = '',
    this.notes = const [],
  });

  /// Creates a [LocationModel] from a Firestore document snapshot.
  factory LocationModel.fromFirestore(Map<String, dynamic> firestoreData, String documentId) {
    return LocationModel(
      locationId: documentId,
      locationName: firestoreData['locationName'] as String,
      branchId: firestoreData['branchId'] as String,
      createdAt: (firestoreData['createdAt'] as dynamic).toDate(),
      isActive: firestoreData['isActive'] as bool,
      address: firestoreData['address'] as String? ?? '',
      latitude: (firestoreData['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (firestoreData['longitude'] as num?)?.toDouble() ?? 0.0,
      clientId: firestoreData['clientId'] as String? ?? '',
      clientName: firestoreData['clientName'] as String? ?? '',
      notes: NoteEntry.listFromFirestore(firestoreData['notes']),
    );
  }

  /// Converts this [LocationModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'branchId': branchId,
      'createdAt': createdAt,
      'isActive': isActive,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'clientId': clientId,
      'clientName': clientName,
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }

  /// Two locations are considered equal if they share the same [locationId].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.locationId == locationId;
  }

  @override
  int get hashCode => locationId.hashCode;
}