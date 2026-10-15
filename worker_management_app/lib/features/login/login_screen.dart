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
      /// gone — only touch state if it's still on screen.
      if (mounted) setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.invalidEmailOrPassword;
        _isLoading = false;
      });
    }
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
                color: Theme.of(context).cardTheme.color ?? context.colors.surface,
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

                      /// Password input field — pressing Enter signs in
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
                      const SizedBox(height: 16),

                      /// Error message display
                      if (_errorMessage != null) ...[
                        MessageBox.error(_errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      /// Login button — colors come from the theme
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