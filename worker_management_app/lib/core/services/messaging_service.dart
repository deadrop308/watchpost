import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// Handles Firebase Cloud Messaging setup and device token management.
/// The FCM token is stored in Firestore so Cloud Functions can send
/// push notifications to specific workers.
class MessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Initializes FCM, requests permissions, and saves the device token.
  /// Should be called once after the user logs in.
  // Future<void> initializeAndSaveToken(String userId) async {
  //   /// Skip on web — FCM push notifications work differently on web
  //   /// and require additional setup we'll handle later
  //   if (kIsWeb) return;
  //
  //   try {
  //     /// Request permission to show notifications on iOS
  //     /// On Android this is granted by default
  //     final NotificationSettings settings =
  //     await _firebaseMessaging.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );
  //
  //     if (settings.authorizationStatus == AuthorizationStatus.denied) return;
  //
  //     /// Get the device's unique FCM token
  //     final String? deviceToken = await _firebaseMessaging.getToken();
  //
  //     if (deviceToken == null) return;
  //
  //     /// Save the token to Firestore so Cloud Functions can use it
  //     await _firestoreService.saveUserFcmToken(
  //       userId: userId,
  //       fcmToken: deviceToken,
  //     );
  //
  //     /// Listen for token refresh and update Firestore accordingly
  //     _firebaseMessaging.onTokenRefresh.listen((String newToken) {
  //       _firestoreService.saveUserFcmToken(
  //         userId: userId,
  //         fcmToken: newToken,
  //       );
  //     });
  //   } catch (error) {
  //     /// Silently fail — notifications are a nice-to-have, not critical
  //   }
  // }

  /// This is a Testing function with logs.
  Future<void> initializeAndSaveToken(String userId) async {
    if (kIsWeb) return;

    try {
      debugPrint('FCM: Requesting permission...');
      final NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      debugPrint('FCM: Getting token...');
      final String? deviceToken = await _firebaseMessaging.getToken();

      debugPrint('FCM: Token received: $deviceToken');

      if (deviceToken == null) return;

      await _firestoreService.saveUserFcmToken(
        userId: userId,
        fcmToken: deviceToken,
      );

      debugPrint('FCM: Token saved successfully');
    } catch (error) {
      debugPrint('FCM: Error: $error');
    }
  }
}