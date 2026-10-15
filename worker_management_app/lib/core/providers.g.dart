// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a single shared instance of [AuthService] throughout the app.

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// Provides a single shared instance of [AuthService] throughout the app.

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// Provides a single shared instance of [AuthService] throughout the app.
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'82398d9f38c720e4ddf6b218248f15089fd4f178';

/// Provides a single shared instance of [FirestoreService] throughout the app.

@ProviderFor(firestoreService)
final firestoreServiceProvider = FirestoreServiceProvider._();

/// Provides a single shared instance of [FirestoreService] throughout the app.

final class FirestoreServiceProvider
    extends
        $FunctionalProvider<
          FirestoreService,
          FirestoreService,
          FirestoreService
        >
    with $Provider<FirestoreService> {
  /// Provides a single shared instance of [FirestoreService] throughout the app.
  FirestoreServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreServiceHash();

  @$internal
  @override
  $ProviderElement<FirestoreService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirestoreService create(Ref ref) {
    return firestoreService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirestoreService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirestoreService>(value),
    );
  }
}

String _$firestoreServiceHash() => r'ab6a4068fcce40bd3123cf65d2f4d942f392e605';

/// Streams the currently authenticated [UserModel].
/// Automatically updates when the user logs in or out.
/// Returns null when no user is logged in.

@ProviderFor(authenticatedUser)
final authenticatedUserProvider = AuthenticatedUserProvider._();

/// Streams the currently authenticated [UserModel].
/// Automatically updates when the user logs in or out.
/// Returns null when no user is logged in.

final class AuthenticatedUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserModel?>,
          UserModel?,
          Stream<UserModel?>
        >
    with $FutureModifier<UserModel?>, $StreamProvider<UserModel?> {
  /// Streams the currently authenticated [UserModel].
  /// Automatically updates when the user logs in or out.
  /// Returns null when no user is logged in.
  AuthenticatedUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticatedUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticatedUserHash();

  @$internal
  @override
  $StreamProviderElement<UserModel?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UserModel?> create(Ref ref) {
    return authenticatedUser(ref);
  }
}

String _$authenticatedUserHash() => r'2e839170f224624f07b75e19a8be475846bb41f5';

/// Provides a single shared instance of [CloudFunctionsService] throughout the app.

@ProviderFor(cloudFunctionsService)
final cloudFunctionsServiceProvider = CloudFunctionsServiceProvider._();

/// Provides a single shared instance of [CloudFunctionsService] throughout the app.

final class CloudFunctionsServiceProvider
    extends
        $FunctionalProvider<
          CloudFunctionsService,
          CloudFunctionsService,
          CloudFunctionsService
        >
    with $Provider<CloudFunctionsService> {
  /// Provides a single shared instance of [CloudFunctionsService] throughout the app.
  CloudFunctionsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudFunctionsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudFunctionsServiceHash();

  @$internal
  @override
  $ProviderElement<CloudFunctionsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudFunctionsService create(Ref ref) {
    return cloudFunctionsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudFunctionsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudFunctionsService>(value),
    );
  }
}

String _$cloudFunctionsServiceHash() =>
    r'ffd40613017b6d6dd5036b14c924ef6f1e23c52b';

/// Provides and persists the current theme mode (light/dark).
/// Reads the saved preference on startup and defaults to light mode.

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// Provides and persists the current theme mode (light/dark).
/// Reads the saved preference on startup and defaults to light mode.
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// Provides and persists the current theme mode (light/dark).
  /// Reads the saved preference on startup and defaults to light mode.
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'68dc7fc94a9eff32848ca948b60389a2154701f5';

/// Provides and persists the current theme mode (light/dark).
/// Reads the saved preference on startup and defaults to light mode.

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provides and persists the current locale (language).
/// Reads the saved preference on startup and defaults to English.

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// Provides and persists the current locale (language).
/// Reads the saved preference on startup and defaults to English.
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, Locale> {
  /// Provides and persists the current locale (language).
  /// Reads the saved preference on startup and defaults to English.
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localeNotifierHash() => r'b8514ac81ba4622b5e19f8a676c2ead1b223471f';

/// Provides and persists the current locale (language).
/// Reads the saved preference on startup and defaults to English.

abstract class _$LocaleNotifier extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
