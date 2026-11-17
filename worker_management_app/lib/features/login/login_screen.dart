import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers.dart';
import '../../core/localization_extension.dart';
import '../shared/message_box.dart';

/// The login screen shown to unauthenticated users.
/// Handles email and password input and signs the user in via [AuthService].
/// After successful login, the router automatically redirects to the
/// appropriate dashboard based on the user's role.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Controls the email input field
  final TextEditingController _emailController = TextEditingController();

  /// Controls the password input field
  final TextEditingController _passwordController = TextEditingController();

  /// Used to validate the form fields before submitting
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  /// Whether the login request is currently in progress
  bool _isLoading = false;

  /// Whether the password field is currently visible
  bool _isPasswordVisible = false;

  /// Error message to display if login fails
  String? _errorMessage;

  @override
  void dispose() {
    /// Clean up controllers when the screen is removed from the widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Attempts to sign in the user with the entered credentials.
  /// Updates loading state and displays errors if login fails.
  Future<void> _attemptLogin() async {
    /// Ignore double taps / Enter presses while a login is running
    if (_isLoading) return;

    /// Validate the form fields first
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthService authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      /// Success: the router redirects away from this screen via the
      /// authenticatedUserProvider stream, so this screen may already be
      /// gone - only touch state if it's still on screen.
      if (mounted) setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invalidEmailOrPassword;
        _isLoading = false;
      });
    }
  }

  /// Opens the "Forgot password?" dialog. Firebase emails a one-time link
  /// (valid for about an hour) that lets the user choose a new password.
  /// No password is ever sent by email.
  Future<void> _showForgotPasswordDialog() async {
    /// Local controller, not disposed manually (see SPEC: dialog controllers).
    /// Pre-filled with whatever was typed in the login email field.
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
    bool isSending = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> sendResetLink() async {
            if (isSending) return;
            if (!resetFormKey.currentState!.validate()) return;
            setDialogState(() {
              isSending = true;
              dialogError = null;
            });

            try {
              /// Send the email in the app's current language (he / en)
              await FirebaseAuth.instance.setLanguageCode(
                Localizations.localeOf(context).languageCode,
              );
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: resetEmailController.text.trim(),
              );

              if (!mounted) return;
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();

              /// Same message whether or not the account exists, so the
              /// screen can't be used to test which emails are registered
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.resetLinkSent),
                  duration: const Duration(seconds: 6),
                ),
              );
            } on FirebaseAuthException catch (error) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                isSending = false;
                dialogError = error.code == 'invalid-email'
                    ? context.l10n.pleaseEnterValidEmail
                    : error.code == 'too-many-requests'
                    ? context.l10n.resetTooManyRequests
                    : context.l10n.resetLinkFailed;
              });
            } catch (_) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                isSending = false;
                dialogError = context.l10n.resetLinkFailed;
              });
            }
          }

          return AlertDialog(
            title: Text(context.l10n.resetPasswordTitle),
            content: SizedBox(
              width: 360,
              child: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.resetPasswordInfo,
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => sendResetLink(),
                      decoration: InputDecoration(
                        labelText: context.l10n.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterEmail;
                        }
                        if (!value.contains('@')) {
                          return context.l10n.pleaseEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      MessageBox.error(dialogError!),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSending ? null : sendResetLink,
                child: isSending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.primary,
                        ),
                      )
                    : Text(context.l10n.sendResetLink),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          /// Keeps a small margin on narrow phones
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                /// Same color as cards: white in light mode, dark grey in dark
                color:
                    Theme.of(context).cardTheme.color ?? context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _loginFormKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// App title
                      Text(
                        context.l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.signInToAccount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      /// Email input field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: context.l10n.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.pleaseEnterEmail;
                          }
                          if (!value.contains('@')) {
                            return context.l10n.pleaseEnterValidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Password input field - pressing Enter signs in
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _attemptLogin(),
                        decoration: InputDecoration(
                          labelText: context.l10n.password,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.pleaseEnterPassword;
                          }
                          return null;
                        },
                      ),

                      /// "Forgot password?" link under the password field
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : _showForgotPasswordDialog,
                          child: Text(context.l10n.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// Error message display
                      if (_errorMessage != null) ...[
                        MessageBox.error(_errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      /// Login button - colors come from the theme
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _attemptLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: context.colors.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.l10n.signIn,
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
