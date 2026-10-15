import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/cloud_functions_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

/// Provides a single shared instance of [AuthService] throughout the app.
@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

/// Provides a single shared instance of [FirestoreService] throughout the app.
@riverpod
FirestoreService firestoreService(Ref ref) {
  return FirestoreService();
}

/// Streams the currently authenticated [UserModel].
/// Automatically updates when the user logs in or out.
/// Returns null when no user is logged in.
@riverpod
Stream<UserModel?> authenticatedUser(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.streamAuthenticatedUser();
}

/// Provides a single shared instance of [CloudFunctionsService] throughout the app.
@riverpod
CloudFunctionsService cloudFunctionsService(Ref ref) {
  return CloudFunctionsService();
}

/// The key used to store the theme mode preference in shared preferences
const String _themeModePreferenceKey = 'theme_mode';

/// The key used to store the locale preference in shared preferences
const String _localePreferenceKey = 'locale';

/// Provides and persists the current theme mode (light/dark).
/// Reads the saved preference on startup and defaults to light mode.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    /// Load saved preference asynchronously after initialization
    _loadSavedThemeMode();
    return ThemeMode.light;
  }

  /// Loads the saved theme mode from shared preferences.
  Future<void> _loadSavedThemeMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? savedThemeMode =
    preferences.getString(_themeModePreferenceKey);
    if (savedThemeMode == 'dark') {
      state = ThemeMode.dark;
    }
  }

  /// Toggles between light and dark mode and saves the preference.
  Future<void> toggleThemeMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await preferences.setString(_themeModePreferenceKey, 'dark');
    } else {
      state = ThemeMode.light;
      await preferences.setString(_themeModePreferenceKey, 'light');
    }
  }
}

/// Provides and persists the current locale (language).
/// Reads the saved preference on startup and defaults to English.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    /// Load saved preference asynchronously after initialization
    _loadSavedLocale();
    return const Locale('en');
  }

  /// Loads the saved locale from shared preferences.
  Future<void> _loadSavedLocale() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? savedLocale =
    preferences.getString(_localePreferenceKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  /// Changes the locale and saves the preference.
  Future<void> changeLocale(Locale newLocale) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    state = newLocale;
    await preferences.setString(_localePreferenceKey, newLocale.languageCode);
  }
}