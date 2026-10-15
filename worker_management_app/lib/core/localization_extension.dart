import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// A convenience extension on [BuildContext] for accessing localized strings.
/// Instead of writing AppLocalizations.of(context)! everywhere,
/// you can simply write context.l10n.someKey
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}