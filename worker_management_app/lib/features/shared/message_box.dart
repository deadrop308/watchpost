import 'package:flutter/material.dart';

/// The kind of message a [MessageBox] shows.
enum MessageBoxType { error, warning }

/// A small colored box for inline messages (form errors, "nothing
/// available" warnings). Colors follow light / dark mode automatically,
/// so screens never hardcode Colors.red[50] / Colors.orange[50] again.
class MessageBox extends StatelessWidget {
  /// The text shown inside the box
  final String message;

  /// Error (red) or warning (orange)
  final MessageBoxType type;

  /// Text alignment inside the box
  final TextAlign textAlign;

  /// A red box for errors — e.g. "Please select a client".
  const MessageBox.error(
      this.message, {
        super.key,
        this.textAlign = TextAlign.center,
      }) : type = MessageBoxType.error;

  /// An orange box for warnings — e.g. "No operation types available".
  const MessageBox.warning(
      this.message, {
        super.key,
        this.textAlign = TextAlign.start,
      }) : type = MessageBoxType.warning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;

    switch (type) {
      case MessageBoxType.error:
        backgroundColor = colors.errorContainer;
        borderColor = colors.error.withValues(alpha: 0.4);
        textColor = colors.onErrorContainer;
      case MessageBoxType.warning:
        backgroundColor =
        isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange[50]!;
        borderColor = isDark ? Colors.orange[700]! : Colors.orange[200]!;
        textColor = isDark ? Colors.orange[200]! : Colors.orange[800]!;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(type == MessageBoxType.error ? 12 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        textAlign: textAlign,
        style: TextStyle(
          color: textColor,
          fontSize: type == MessageBoxType.error ? 13 : 14,
        ),
      ),
    );
  }
}