import 'close_form_model.dart';

/// Represents the current status of a work call.
enum CallStatus {
  open,
  arrived,
  paused,
  closed,
}

/// Converts a string from Firestore into a [CallStatus] enum value.
CallStatus callStatusFromString(String statusString) {
  switch (statusString) {
    case 'closed':
      return CallStatus.closed;
    case 'arrived':
      return CallStatus.arrived;
    case 'paused':
      return CallStatus.paused;
    case 'open':
    default:
      return CallStatus.open;
  }
}

/// Converts a [CallStatus] enum value into a string for storing in Firestore.
String callStatusToString(CallStatus status) {
  switch (status) {
    case CallStatus.closed:
      return 'closed';
    case CallStatus.arrived:
      return 'arrived';
    case CallStatus.paused:
      return 'paused';
    case CallStatus.open:
      return 'open';
  }
}

/// Represents a work call opened by a technician worker.
/// A call tracks the operation, location, timing, and closure signature.
class CallModel {
  /// The unique Firestore document ID for this call
  final String callId;

  /// The name of the operation being performed
  final String operationName;

  /// The name of the location where the work is taking place
  final String locationName;

  /// The latitude coordinate of the location at the time the call was created.
  /// Used for navigation.
  final double locationLatitude;

  /// The longitude coordinate of the location at the time the call was created.
  /// Used for navigation.
  final double locationLongitude;

  /// The ID of the client associated with this call
  final String clientId;

  /// The name of the client, stored directly for easy display
  final String clientName;

  /// When the call was opened by the worker
  final DateTime startTime;

  /// When the call was closed — null if the call is still open
  final DateTime? endTime;

  /// Whether the call is currently open or has been closed
  final CallStatus status;

  /// The Firebase Auth ID of the worker who opened this call
  final String workerUserId;

  /// The full name of the worker, stored directly for easy display
  final String workerFullName;

  /// The branch this call belongs to, used to filter by manager
  final String branchId;

  /// The URL of the signature image stored in Firebase Storage.
  /// Null if the call has not been closed yet.
  final String? signatureImageUrl;

  /// When the worker arrived at the location.
  /// Null if the worker has not yet marked arrival.
  final DateTime? arrivedAt;

  /// Notes added by the worker when closing the call.
  /// Null if no notes were added.
  final String? notes;

  /// The status the call was in before being paused.
  /// Used to restore the correct status when resuming.
  final String? previousStatus;

  /// The ID of the manager who assigned this call to the worker.
  /// Null if the worker opened the call themselves.
  final String? assignedByManagerId;

  /// Instructions from the manager when assigning a call.
  /// Null if the call was opened by the worker themselves.
  final String? managerInstructions;

  /// Copy of the operation type's close form, taken when the call was opened.
  /// Calls opened before this feature use the default form.
  final CloseFormConfig closeForm;

  /// Checklist results recorded when closing: item ID → checked or not
  final Map<String, bool> checklistResults;

  const CallModel({
    required this.callId,
    required this.operationName,
    required this.locationName,
    this.locationLatitude = 0.0,
    this.locationLongitude = 0.0,
    this.clientId = '',
    this.clientName = '',
    required this.startTime,
    this.endTime,
    required this.status,
    required this.workerUserId,
    required this.workerFullName,
    required this.branchId,
    this.signatureImageUrl,
    this.arrivedAt,
    this.notes,
    this.previousStatus,
    this.assignedByManagerId,
    this.managerInstructions,
    this.closeForm = CloseFormConfig.defaultConfig,
    this.checklistResults = const {},
  });

  /// Creates a [CallModel] from a Firestore document snapshot.
  factory CallModel.fromFirestore(Map<String, dynamic> firestoreData, String documentId) {
    return CallModel(
      callId: documentId,
      operationName: firestoreData['operationName'] as String,
      locationName: firestoreData['locationName'] as String,
      locationLatitude: (firestoreData['locationLatitude'] as num?)?.toDouble() ?? 0.0,
      locationLongitude: (firestoreData['locationLongitude'] as num?)?.toDouble() ?? 0.0,
      clientId: firestoreData['clientId'] as String? ?? '',
      clientName: firestoreData['clientName'] as String? ?? '',
      startTime: (firestoreData['startTime'] as dynamic).toDate(),
      endTime: firestoreData['endTime'] != null
          ? (firestoreData['endTime'] as dynamic).toDate()
          : null,
      status: callStatusFromString(firestoreData['status'] as String),
      workerUserId: firestoreData['workerUserId'] as String,
      workerFullName: firestoreData['workerFullName'] as String,
      branchId: firestoreData['branchId'] as String,
      signatureImageUrl: firestoreData['signatureImageUrl'] as String?,
      arrivedAt: firestoreData['arrivedAt'] != null
          ? (firestoreData['arrivedAt'] as dynamic).toDate()
          : null,
      notes: firestoreData['notes'] as String?,
      previousStatus: firestoreData['previousStatus'] as String?,
      assignedByManagerId: firestoreData['assignedByManagerId'] as String?,
      managerInstructions: firestoreData['managerInstructions'] as String?,
      closeForm: CloseFormConfig.fromMap(firestoreData['closeForm']),
      checklistResults: (firestoreData['checklistResults'] as Map?)?.map(
            (key, value) => MapEntry(key as String, value == true),
      ) ??
          const {},
    );
  }

  /// Converts this [CallModel] into a map for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'operationName': operationName,
      'locationName': locationName,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'clientId': clientId,
      'clientName': clientName,
      'startTime': startTime,
      'endTime': endTime,
      'status': callStatusToString(status),
      'workerUserId': workerUserId,
      'workerFullName': workerFullName,
      'branchId': branchId,
      'signatureImageUrl': signatureImageUrl,
      'arrivedAt': arrivedAt,
      'notes': notes,
      'previousStatus': previousStatus,
      'assignedByManagerId': assignedByManagerId,
      'managerInstructions': managerInstructions,
      'closeForm': closeForm.toMap(),
      'checklistResults': checklistResults,
    };
  }
}