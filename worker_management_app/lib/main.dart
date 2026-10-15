import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'app/router.dart';
import 'core/providers.dart';
import 'firebase_options.dart';
import 'app/app_theme.dart';

/// reCAPTCHA Enterprise site key for watchpost-il.web.app.
/// This key is public by design (it ships in the web page); it only works
/// on the domains registered for it in Google Cloud.
const String _recaptchaSiteKey = '6LcpTe4tAAAAAOQJFL9IiZOAawvHQyzJFftyH8c9';

/// Entry point of the application.
/// Initializes Firebase and App Check before running the app.
void main() async {
  // Ensures Flutter engine is ready before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options for the current platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check proves to Firebase that requests come from the real Watchpost
  // app: Play Integrity on Android, reCAPTCHA Enterprise on web.
  // Debug runs (flutter run / VS Code) use the debug provider instead, which
  // prints a debug token to register in Firebase console > App Check.
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerWeb: kDebugMode
          ? WebDebugProvider()
          : ReCaptchaEnterpriseProvider(_recaptchaSiteKey),
    );
  } catch (error) {
    // Never block app start because of App Check. While App Check is not
    // enforced, requests still work without a token.
    debugPrint('App Check activation failed: $error');
  }

  // ProviderScope is required at the root for Riverpod to work
  runApp(const ProviderScope(child: WorkerManagementApp()));
}

/// Root widget of the application.
/// Uses [ConsumerWidget] to access the Riverpod [appRouterProvider].
class WorkerManagementApp extends ConsumerWidget {
  const WorkerManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider so the app reacts to auth state changes
    final appRouter = ref.watch(appRouterProvider);
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);
    final Locale currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      /// Shown in the Android recent-apps screen and the browser tab
      title: 'Watchpost',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,

      /// Apply the current theme mode
      themeMode: currentThemeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      /// Apply the current locale
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('he')],
    );
  }
}
