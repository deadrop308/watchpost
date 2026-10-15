import 'package:cloud_functions/cloud_functions.dart';

/// Handles all Firebase Cloud Functions calls.
/// Used for operations that require server-side logic such as
/// creating user accounts without affecting the current session.
class CloudFunctionsService {
  /// The Firebase Cloud Functions instance
  final FirebaseFunctions _functionsInstance = FirebaseFunctions.instance;

  /// Calls the createWorkerAccount Cloud Function.
  /// Creates a Firebase Auth account, Firestore document,
  /// and sends login credentials to the worker's email.
  Future<void> createWorkerAccount({
    required String emailAddress,
    required String fullName,
  }) async {
    final HttpsCallable callable =
    _functionsInstance.httpsCallable('createWorkerAccount');

    await callable.call({
      'emailAddress': emailAddress,
      'fullName': fullName,
    });
  }

  /// Calls the createManagerAccount Cloud Function.
  /// Creates a Firebase Auth account, Firestore document,
  /// and sends login credentials to the manager's email.
  Future<void> createManagerAccount({
    required String emailAddress,
    required String fullName,
    required String branchId,
  }) async {
    final HttpsCallable callable =
    _functionsInstance.httpsCallable('createManagerAccount');

    await callable.call({
      'emailAddress': emailAddress,
      'fullName': fullName,
      'branchId': branchId,
    });
  }

  /// Calls the setUserActive Cloud Function.
  /// Activates or deactivates a user. When deactivating, the server also
  /// disables the user's login and ends any session they already have,
  /// so they are locked out immediately.
  /// Managers may change workers in their own branch; admins may change managers.
  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final HttpsCallable callable =
    _functionsInstance.httpsCallable('setUserActive');

    await callable.call({
      'userId': userId,
      'active': isActive,
    });
  }

  /// Calls the sendCallAssignmentNotification Cloud Function.
  /// Sends a push notification to the worker when a manager assigns them a call.
  Future<void> sendCallAssignmentNotification({
    required String workerUserId,
    required String operationName,
    required String locationName,
    String? managerInstructions,
  }) async {
    final HttpsCallable callable =
    _functionsInstance.httpsCallable('sendCallAssignmentNotification');

    await callable.call({
      'workerUserId': workerUserId,
      'operationName': operationName,
      'locationName': locationName,
      'managerInstructions': managerInstructions ?? '',
    });
  }
}