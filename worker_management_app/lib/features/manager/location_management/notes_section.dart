import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/note_entry_model.dart';

/// An expandable list of timestamped notes with add and delete actions.
/// Shared by clients and locations — the parent supplies the callbacks
/// that actually write to Firestore.
class NotesSection extends StatelessWidget {
  /// Unique ID of the owner (client or location), used to keep the
  /// expanded/collapsed state stable when the list rebuilds
  final String ownerId;

  /// The notes to display, already sorted newest first
  final List<NoteEntry> notes;

  /// Saves a new note with the given text
  final Future<void> Function(String text) onAddNote;

  /// Permanently deletes the given note
  final Future<void> Function(NoteEntry note) onDeleteNote;

  const NotesSection({
    super.key,
    required this.ownerId,
    required this.notes,
    required this.onAddNote,
    required this.onDeleteNote,
  });

  /// Formats a [DateTime] into a readable date/time string.
  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Opens a dialog to write a new note.
  Future<void> _showAddNoteDialog(BuildContext context) async {
    /// Local controller — not disposed manually (see SPEC: dialog controllers)
    final TextEditingController noteController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.addNote),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: TextFormField(
                controller: noteController,
                autofocus: true,
                maxLength: 300,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.noteText,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.pleaseEnterNote;
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
              isSaving ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                try {
                  await onAddNote(noteController.text.trim());
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.failedToSaveNote),
                        backgroundColor: context.colors.error,
                      ),
                    );
                  }
                }
              },
              /// Colors come from the theme
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks for confirmation, then permanently deletes the note.
  Future<void> _confirmDeleteNote(BuildContext context, NoteEntry note) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await onDeleteNote(note);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToDeleteNote),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = context.colors.onSurfaceVariant;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    /// Sticky-note yellow, softened in dark mode
    final Color noteBackground =
    isDark ? Colors.amber.withValues(alpha: 0.12) : Colors.amber[50]!;
    final Color noteBorder = isDark
        ? Colors.amber.withValues(alpha: 0.35)
        : Colors.amber[200]!;

    return ExpansionTile(
      key: PageStorageKey<String>('notes-$ownerId'),
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      /// Remove the default Material 3 divider lines inside the card
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(Icons.sticky_note_2_outlined,
          size: 20, color: mutedColor),
      title: Text(
        '${context.l10n.notes} (${notes.length})',
        style: TextStyle(fontSize: 13, color: context.colors.onSurface),
      ),
      children: [
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.l10n.noNotesYet,
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
          ),

        /// Note entries, newest first
        ...notes.map(
              (note) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: noteBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: noteBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.text, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDateTime(note.createdAt)} · ${note.authorName}',
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                /// Delete (X) button for this note entry
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: mutedColor,
                  tooltip: context.l10n.delete,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteNote(context, note),
                ),
              ],
            ),
          ),
        ),

        /// Add note button
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => _showAddNoteDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.addNote),
          ),
        ),
      ],
    );
  }
}