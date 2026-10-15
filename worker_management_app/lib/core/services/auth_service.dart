import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

/// Handles all Firebase Authentication operations.
/// Works together with [FirestoreService] to fetch the full user profile
/// after authentication.
class AuthService {
  /// The Firebase Auth instance used for all authentication operations
  final FirebaseAuth _firebaseAuthInstance = FirebaseAuth.instance;

  /// The Firestore service used to fetch user profile data after login
  final FirestoreService _firestoreService = FirestoreService();

  /// Returns a stream that emits the current [UserModel] whenever the
  /// authentication state changes (login, logout, app restart).
  /// Emits null when no user is logged in.
  Stream<UserModel?> streamAuthenticatedUser() {
    return _firebaseAuthInstance.authStateChanges().asyncMap(
          (firebaseUser) async {
        if (firebaseUser == null) return null;
        return await _firestoreService.fetchUserById(firebaseUser.uid);
      },
    );
  }

  /// Signs in a user with their email address and password.
  /// Returns the [UserModel] of the signed in user.
  /// Throws a [FirebaseAuthException] if login fails.
  Future<UserModel?> signInWithEmailAndPassword({
    required String emailAddress,
    required String password,
  }) async {
    final userCredential = await _firebaseAuthInstance
        .signInWithEmailAndPassword(
      email: emailAddress,
      password: password,
    );

    if (userCredential.user == null) return null;

    final UserModel? user =
    await _firestoreService.fetchUserById(userCredential.user!.uid);

    /// Initialize push notifications after successful login
    if (user != null) {
      final MessagingService messagingService = MessagingService();
      await messagingService.initializeAndSaveToken(user.userId);
    }

    return user;
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    await _firebaseAuthInstance.signOut();
  }

  /// Returns the Firebase Auth ID of the currently logged in user.
  /// Returns null if no user is logged in.
  String? getCurrentUserId() {
    return _firebaseAuthInstance.currentUser?.uid;
  }
}