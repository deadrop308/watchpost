import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import '../models/location_model.dart';
import '../models/branch_model.dart';
import '../models/operation_type_model.dart';
import '../models/client_model.dart';
import '../models/note_entry_model.dart';
import '../models/close_form_model.dart';

/// Handles all read and write operations with Firebase Firestore.
/// This is the single point of contact between the app and the database.
class FirestoreService {
  /// The Firestore instance used for all database operations
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // COLLECTION NAMES
  // ─────────────────────────────────────────────

  static const String _usersCollection = 'users';
  static const String _callsCollection = 'calls';
  static const String _locationsCollection = 'locations';
  static const String _clientsCollection = 'clients';
  static const String _branchesCollection = 'branches';
  static const String _operationTypesCollection = 'operationTypes';

  // ─────────────────────────────────────────────
  // USER OPERATIONS
  // ─────────────────────────────────────────────

  /// Fetches a single user document from Firestore by their user ID.
  Future<UserModel?> fetchUserById(String userId) async {
    final documentSnapshot = await _firestoreInstance
        .collection(_usersCollection)
        .doc(userId)
        .get();

    if (!documentSnapshot.exists) return null;

    return UserModel.fromFirestore(
      documentSnapshot.data()!,
      documentSnapshot.id,
    );
  }

  /// Creates a new user document in Firestore.
  /// Called after Firebase Auth account creation.
  Future<void> createUserDocument(UserModel newUser) async {
    await _firestoreInstance
        .collection(_usersCollection)
        .doc(newUser.userId)
        .set(newUser.toFirestore());
  }

  /// Fetches all active worker accounts belonging to a specific branch.
  Future<List<UserModel>> fetchWorkersByBranch(String branchId) async {
    final querySnapshot = await _firestoreInstance
        .collection(_usersCollection)
        .where('branchId', isEqualTo: branchId)
        .where('role', isEqualTo: 'worker')
        .where('isActive', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Fetches all active manager accounts.
  /// Used by the admin to manage manager accounts.
  Future<List<UserModel>> fetchAllManagers() async {
    final querySnapshot = await _firestoreInstance
        .collection(_usersCollection)
        .where('role', isEqualTo: 'manager')
        .where('isActive', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Fetches all active workers and managers in a specific branch.
  /// Used by the manager when assigning a call to a team member.
  Future<List<UserModel>> fetchAllBranchMembers(String branchId) async {
    final querySnapshot = await _firestoreInstance
        .collection(_usersCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Soft-deletes a user by setting their isActive flag to false.
  /// The document is kept in Firestore for historical reference.
  Future<void> deactivateUser(String userId) async {
    await _firestoreInstance
        .collection(_usersCollection)
        .doc(userId)
        .update({'isActive': false});
  }

  /// Saves or updates the FCM device token for a user.
  /// Used to send push notifications to specific devices.
  Future<void> saveUserFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    await _firestoreInstance
        .collection(_usersCollection)
        .doc(userId)
        .update({'fcmToken': fcmToken});
  }

  // ─────────────────────────────────────────────
  // CALL OPERATIONS
  // ─────────────────────────────────────────────

  /// Creates a new work call document in Firestore.
  /// Called when a worker opens a new call.
  Future<void> createCall(CallModel newCall) async {
    await _firestoreInstance
        .collection(_callsCollection)
        .doc(newCall.callId)
        .set(newCall.toFirestore());
  }

  /// Closes an existing call: sets end time and status, and saves
  /// the signature URL, notes and checklist results (whichever apply).
  Future<void> closeCall({
    required String callId,
    required DateTime endTime,
    String? signatureImageUrl,
    String? notes,
    Map<String, bool> checklistResults = const {},
  }) async {
    await _firestoreInstance
        .collection(_callsCollection)
        .doc(callId)
        .update({
      'endTime': endTime,
      'status': 'closed',
      'signatureImageUrl': signatureImageUrl,
      'notes': notes,
      'checklistResults': checklistResults,
    });
  }

  /// Returns a real-time stream of all active calls for a specific worker.
  /// Active means open, arrived or paused — anything that is not closed.
  Stream<List<CallModel>> streamWorkerActiveCalls(String workerUserId) {
    return _firestoreInstance
        .collection(_callsCollection)
        .where('workerUserId', isEqualTo: workerUserId)
        .where('status', whereIn: ['open', 'arrived', 'paused'])
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => CallModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Returns a real-time stream of all calls for a specific branch today.
  Stream<List<CallModel>> streamBranchCallsForToday(String branchId) {
    final DateTime startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return _firestoreInstance
        .collection(_callsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('startTime', isGreaterThanOrEqualTo: startOfToday)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => CallModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Returns a real-time stream of all calls for a specific branch that are
  /// either started today OR still active (not closed) from previous days.
  /// Used by the manager dashboard.
  Stream<List<CallModel>> streamBranchDashboardCalls(String branchId) {
    final DateTime startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    /// Stream today's calls
    final Stream<List<CallModel>> todayCallsStream = _firestoreInstance
        .collection(_callsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('startTime', isGreaterThanOrEqualTo: startOfToday)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => CallModel.fromFirestore(doc.data(), doc.id))
        .toList());

    /// Stream unclosed calls from previous days
    final Stream<List<CallModel>> unclosedOldCallsStream = _firestoreInstance
        .collection(_callsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('startTime', isLessThan: startOfToday)
        .where('status', whereIn: ['open', 'arrived', 'paused'])
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => CallModel.fromFirestore(doc.data(), doc.id))
        .toList());

    /// Combine both streams into one list
    return todayCallsStream.asyncMap((todayCalls) async {
      final List<CallModel> unclosedOldCalls =
      await unclosedOldCallsStream.first;
      return [...unclosedOldCalls, ...todayCalls];
    });
  }

  /// Fetches all calls for a specific branch within a given month.
  /// Used by the manager report screen.
  Future<List<CallModel>> fetchBranchCallsByMonth({
    required String branchId,
    required int year,
    required int month,
  }) async {
    final DateTime startOfMonth = DateTime(year, month, 1);
    final DateTime startOfNextMonth = DateTime(year, month + 1, 1);

    final querySnapshot = await _firestoreInstance
        .collection(_callsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('startTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('startTime', isLessThan: startOfNextMonth)
        .orderBy('startTime', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => CallModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Marks a call as arrived by setting the arrivedAt timestamp
  /// and updating the status to arrived.
  Future<void> markCallAsArrived({
    required String callId,
    required DateTime arrivedAt,
  }) async {
    await _firestoreInstance
        .collection(_callsCollection)
        .doc(callId)
        .update({
      'arrivedAt': arrivedAt,
      'status': 'arrived',
    });
  }

  /// Pauses an active call by storing the current status
  /// and setting the status to paused.
  Future<void> pauseCall({
    required String callId,
    required String currentStatus,
  }) async {
    await _firestoreInstance
        .collection(_callsCollection)
        .doc(callId)
        .update({
      'previousStatus': currentStatus,
      'status': 'paused',
    });
  }

  /// Resumes a paused call by restoring the previous status.
  Future<void> resumeCall({
    required String callId,
    required String previousStatus,
  }) async {
    await _firestoreInstance
        .collection(_callsCollection)
        .doc(callId)
        .update({
      'status': previousStatus,
      'previousStatus': null,
    });
  }

  // ─────────────────────────────────────────────
  // LOCATION OPERATIONS
  // ─────────────────────────────────────────────

  /// Returns a real-time stream of all active locations for a specific branch.
  Stream<List<LocationModel>> streamActiveLocationsByBranch(String branchId) {
    return _firestoreInstance
        .collection(_locationsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .orderBy('locationName', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => LocationModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Returns a real-time stream of all active locations for a specific client.
  /// Filters by branchId too, so the query matches the security rules.
  Stream<List<LocationModel>> streamActiveLocationsByClient({
    required String branchId,
    required String clientId,
  }) {
    return _firestoreInstance
        .collection(_locationsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('locationName', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => LocationModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Fetches all active locations for a specific client (non-streaming, for filters).
  /// Filters by branchId too, so the query matches the security rules.
  Future<List<LocationModel>> fetchActiveLocationsByClient({
    required String branchId,
    required String clientId,
  }) async {
    final querySnapshot = await _firestoreInstance
        .collection(_locationsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('locationName', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => LocationModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Fetches all active locations for a branch (non-streaming, for filters).
  Future<List<LocationModel>> fetchAllActiveLocationsByBranch(
      String branchId) async {
    final querySnapshot = await _firestoreInstance
        .collection(_locationsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .orderBy('locationName', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => LocationModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Creates a new location document in Firestore.
  Future<void> createLocation(LocationModel newLocation) async {
    await _firestoreInstance
        .collection(_locationsCollection)
        .doc(newLocation.locationId)
        .set(newLocation.toFirestore());
  }

  /// Updates the name, address and coordinates of an existing location.
  Future<void> updateLocation({
    required String locationId,
    required String newLocationName,
    required String newAddress,
    required double newLatitude,
    required double newLongitude,
  }) async {
    await _firestoreInstance
        .collection(_locationsCollection)
        .doc(locationId)
        .update({
      'locationName': newLocationName,
      'address': newAddress,
      'latitude': newLatitude,
      'longitude': newLongitude,
    });
  }

  /// Soft-deletes a location by setting its isActive flag to false.
  /// Existing calls that reference this location are unaffected.
  Future<void> deactivateLocation(String locationId) async {
    await _firestoreInstance
        .collection(_locationsCollection)
        .doc(locationId)
        .update({'isActive': false});
  }

  // ─────────────────────────────────────────────
  // CLIENT OPERATIONS
  // ─────────────────────────────────────────────

  /// Returns a real-time stream of all active clients for a specific branch.
  Stream<List<ClientModel>> streamActiveClientsByBranch(String branchId) {
    return _firestoreInstance
        .collection(_clientsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .orderBy('clientName', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => ClientModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Fetches all active clients for a branch (non-streaming, for filters).
  Future<List<ClientModel>> fetchAllActiveClientsByBranch(
      String branchId) async {
    final querySnapshot = await _firestoreInstance
        .collection(_clientsCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .orderBy('clientName', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => ClientModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Creates a new client document in Firestore.
  Future<void> createClient(ClientModel newClient) async {
    await _firestoreInstance
        .collection(_clientsCollection)
        .doc(newClient.clientId)
        .set(newClient.toFirestore());
  }

  /// Updates the name of an existing client.
  Future<void> updateClientName({
    required String clientId,
    required String newClientName,
  }) async {
    await _firestoreInstance
        .collection(_clientsCollection)
        .doc(clientId)
        .update({'clientName': newClientName});
  }

  /// Soft-deletes a client by setting its isActive flag to false.
  Future<void> deactivateClient(String clientId) async {
    await _firestoreInstance
        .collection(_clientsCollection)
        .doc(clientId)
        .update({'isActive': false});
  }

  // ─────────────────────────────────────────────
  // BRANCH OPERATIONS
  // ─────────────────────────────────────────────

  /// Returns a real-time stream of all active branches.
  /// Used by the admin branch management tab.
  Stream<List<BranchModel>> streamActiveBranches() {
    return _firestoreInstance
        .collection(_branchesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('branchName', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) => BranchModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Updates the name of an existing branch.
  Future<void> updateBranchName({
    required String branchId,
    required String newBranchName,
  }) async {
    await _firestoreInstance
        .collection(_branchesCollection)
        .doc(branchId)
        .update({'branchName': newBranchName});
  }

  /// Fetches all active branches.
  /// Used by the admin when creating a new manager account
  /// to populate the branch selection dropdown.
  Future<List<BranchModel>> fetchAllActiveBranches() async {
    final querySnapshot = await _firestoreInstance
        .collection(_branchesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('branchName', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => BranchModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Creates a new branch document in Firestore.
  /// Called by the admin when adding a new company branch.
  Future<void> createBranch(BranchModel newBranch) async {
    await _firestoreInstance
        .collection(_branchesCollection)
        .doc(newBranch.branchId)
        .set(newBranch.toFirestore());
  }

  /// Soft-deletes a branch by setting its isActive flag to false.
  Future<void> deactivateBranch(String branchId) async {
    await _firestoreInstance
        .collection(_branchesCollection)
        .doc(branchId)
        .update({'isActive': false});
  }

  // ─────────────────────────────────────────────
  // OPERATION TYPE OPERATIONS
  // ─────────────────────────────────────────────

  /// Returns a real-time stream of all active operation types for a branch.
  /// Used by the worker dropdown when opening a new call.
  Stream<List<OperationTypeModel>> streamActiveOperationTypesByBranch(
      String branchId) {
    return _firestoreInstance
        .collection(_operationTypesCollection)
        .where('branchId', isEqualTo: branchId)
        .where('isActive', isEqualTo: true)
        .orderBy('operationTypeName', descending: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
        .map((doc) =>
        OperationTypeModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Creates a new operation type document in Firestore.
  Future<void> createOperationType(
      OperationTypeModel newOperationType) async {
    await _firestoreInstance
        .collection(_operationTypesCollection)
        .doc(newOperationType.operationTypeId)
        .set(newOperationType.toFirestore());
  }

  /// Updates the name of an existing operation type.
  Future<void> updateOperationTypeName({
    required String operationTypeId,
    required String newOperationTypeName,
  }) async {
    await _firestoreInstance
        .collection(_operationTypesCollection)
        .doc(operationTypeId)
        .update({'operationTypeName': newOperationTypeName});
  }

  /// Updates the name and close-call form of an existing operation type.
  /// Calls already opened keep their own copy of the old form.
  Future<void> updateOperationType({
    required String operationTypeId,
    required String newOperationTypeName,
    required CloseFormConfig newCloseForm,
  }) async {
    await _firestoreInstance
        .collection(_operationTypesCollection)
        .doc(operationTypeId)
        .update({
      'operationTypeName': newOperationTypeName,
      'closeForm': newCloseForm.toMap(),
    });
  }

  /// Soft-deletes an operation type by setting its isActive flag to false.
  /// Existing calls that reference this operation type name are unaffected.
  Future<void> deactivateOperationType(String operationTypeId) async {
    await _firestoreInstance
        .collection(_operationTypesCollection)
        .doc(operationTypeId)
        .update({'isActive': false});
  }

  // ─────────────────────────────────────────────
  // NOTE OPERATIONS (shared by clients and locations)
  // ─────────────────────────────────────────────

  /// Adds a note entry to a client.
  Future<void> addClientNote({
    required String clientId,
    required NoteEntry note,
  }) =>
      _addNote(_clientsCollection, clientId, note);

  /// Permanently removes a note entry from a client.
  Future<void> deleteClientNote({
    required String clientId,
    required String noteId,
  }) =>
      _deleteNote(_clientsCollection, clientId, noteId);

  /// Adds a note entry to a location.
  Future<void> addLocationNote({
    required String locationId,
    required NoteEntry note,
  }) =>
      _addNote(_locationsCollection, locationId, note);

  /// Permanently removes a note entry from a location.
  Future<void> deleteLocationNote({
    required String locationId,
    required String noteId,
  }) =>
      _deleteNote(_locationsCollection, locationId, noteId);

  /// Appends a note to the 'notes' list of any document.
  /// Creates the list if the document doesn't have one yet.
  Future<void> _addNote(
      String collection, String documentId, NoteEntry note) async {
    await _firestoreInstance.collection(collection).doc(documentId).update({
      'notes': FieldValue.arrayUnion([note.toMap()]),
    });
  }

  /// Removes a note by its ID from the 'notes' list of any document.
  /// Runs as a transaction so two managers editing at once
  /// can't overwrite each other's changes.
  Future<void> _deleteNote(
      String collection, String documentId, String noteId) async {
    final DocumentReference<Map<String, dynamic>> documentReference =
    _firestoreInstance.collection(collection).doc(documentId);

    await _firestoreInstance.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
      await transaction.get(documentReference);
      final List<dynamic> currentNotes =
          (snapshot.data()?['notes'] as List<dynamic>?) ?? [];
      final List<dynamic> remainingNotes = currentNotes
          .where((note) => note is Map && note['noteId'] != noteId)
          .toList();
      transaction.update(documentReference, {'notes': remainingNotes});
    });
  }
}