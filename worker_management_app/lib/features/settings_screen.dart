import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_theme.dart';
import '../core/localization_extension.dart';
import '../core/models/user_model.dart';
import '../core/providers.dart';
import '../core/services/auth_service.dart';

/// The settings screen shared by all roles (worker, manager, admin).
/// Allows changing language, theme mode, opening the privacy policy and
/// logging out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);
    final Locale currentLocale = ref.watch(localeProvider);

    return authenticatedUserAsyncValue.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _buildSettingsScreen(
          context,
          ref,
          currentUser,
          currentThemeMode,
          currentLocale,
        );
      },
    );
  }

  Widget _buildSettingsScreen(
    BuildContext context,
    WidgetRef ref,
    UserModel currentUser,
    ThemeMode currentThemeMode,
    Locale currentLocale,
  ) {
    /// First letter for the avatar - safe even if the name is empty
    final String trimmedName = currentUser.fullName.trim();
    final String avatarLetter = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            /// Extra bottom padding keeps the last card above the Android
            /// navigation bar
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              /// Logged in as card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: context.colors.primary,
                        child: Text(
                          avatarLetter,
                          style: TextStyle(
                            color: context.colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      /// Expanded + ellipsis so a long email can't overflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              currentUser.emailAddress,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Language selector card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.language,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          /// English button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ref
                                  .read(localeProvider.notifier)
                                  .changeLocale(const Locale('en')),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    currentLocale.languageCode == 'en'
                                    ? context.colors.primary
                                    : null,
                                foregroundColor:
                                    currentLocale.languageCode == 'en'
                                    ? context.colors.onPrimary
                                    : null,
                              ),
                              child: Text(context.l10n.english),
                            ),
                          ),
                          const SizedBox(width: 8),

                          /// Hebrew button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ref
                                  .read(localeProvider.notifier)
                                  .changeLocale(const Locale('he')),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    currentLocale.languageCode == 'he'
                                    ? context.colors.primary
                                    : null,
                                foregroundColor:
                                    currentLocale.languageCode == 'he'
                                    ? context.colors.onPrimary
                                    : null,
                              ),
                              child: Text(context.l10n.hebrew),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// Dark mode toggle card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(context.l10n.darkMode),
                  secondary: Icon(
                    currentThemeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: context.colors.primary,
                  ),

                  /// Switch colors come from the theme
                  value: currentThemeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggleThemeMode(),
                ),
              ),
              const SizedBox(height: 16),

              /// Privacy policy link (required by Google Play)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(context.l10n.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openPrivacyPolicy(context, currentLocale),
                ),
              ),
              const SizedBox(height: 16),

              /// Logout button
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: context.colors.error),
                  title: Text(
                    context.l10n.logout,
                    style: TextStyle(color: context.colors.error),
                  ),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the privacy policy page in the browser, on the Hebrew section
  /// when the app is in Hebrew.
  Future<void> _openPrivacyPolicy(
    BuildContext context,
    Locale currentLocale,
  ) async {
    final String section = currentLocale.languageCode == 'he' ? 'he' : 'en';
    final Uri policyUri = Uri.parse(
      'https://watchpost-il.web.app/privacy.html#$section',
    );

    /// Captured before the await so it's safe to use afterwards
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failedMessage = context.l10n.couldNotOpenLink;

    /// launchUrl directly (canLaunchUrl is unreliable on Android 11+)
    bool opened = false;
    try {
      opened = await launchUrl(policyUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  /// Shows a confirmation dialog before logging out.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final AuthService authService = ref.read(authServiceProvider);
              await authService.signOut();

              /// Router will automatically redirect to login screen
              /// after sign out via the authenticatedUserProvider stream
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }
}
