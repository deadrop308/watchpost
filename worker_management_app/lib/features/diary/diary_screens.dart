import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../core/localization_extension.dart';
import '../../core/models/client_model.dart';
import '../../core/models/field_note_model.dart';
import '../../core/models/location_model.dart';
import '../../core/models/note_entry_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// All non-expired field notes of a branch, shared by every Diary screen.
/// While any Diary screen is open there is ONE live query; it stops when
/// the worker leaves the Diary (autoDispose).
final branchFieldNotesProvider = StreamProvider.autoDispose
    .family<List<FieldNoteModel>, String>((ref, branchId) {
  final FirestoreService firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamActiveFieldNotesByBranch(branchId);
});

/// How many days notes are kept in this branch (default 7).
final fieldNoteRetentionDaysProvider =
    FutureProvider.autoDispose.family<int, String>((ref, branchId) {
  final FirestoreService firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.fetchFieldNoteRetentionDays(branchId);
});

// ─────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────

/// Notes that haven't expired yet (the TTL deletion can lag behind).
List<FieldNoteModel> _activeNotes(List<FieldNoteModel> notes) =>
    notes.where((note) => !note.isExpired).toList();

/// "Today 14:20", "Yesterday 09:10" or "25/10 08:15".
String _formatNoteTime(BuildContext context, DateTime dateTime) {
  final String time =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime noteDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final int daysAgo = today.difference(noteDay).inDays;

  if (daysAgo == 0) return context.l10n.diaryToday(time);
  if (daysAgo == 1) return context.l10n.diaryYesterday(time);
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month $time';
}

/// Small pill shown on businesses and machines that have recent notes.
class _NotesBadge extends StatelessWidget {
  final List<FieldNoteModel> notes;

  const _NotesBadge({required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    /// Notes arrive newest first, so the first one is the latest
    final String lastNoteTime = _formatNoteTime(context, notes.first.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${context.l10n.diaryNoteCount(notes.length)} · ${context.l10n.diaryLastNote(lastNoteTime)}',
        style: TextStyle(
          fontSize: 12,
          color: context.colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Centered muted message for empty lists and errors.
class _DiaryMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DiaryMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = context.colors.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 1. BUSINESSES (shown inside the worker dashboard's Diary section)
// ─────────────────────────────────────────────

/// The Diary's first level: the branch's businesses (clients), with a
/// search box and a badge for businesses that have recent notes.
class DiaryBusinessesView extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const DiaryBusinessesView({super.key, required this.currentUser});

  @override
  ConsumerState<DiaryBusinessesView> createState() =>
      _DiaryBusinessesViewState();
}

class _DiaryBusinessesViewState extends ConsumerState<DiaryBusinessesView> {
  /// Created once so rebuilds don't resubscribe
  late final Stream<List<ClientModel>> _clientsStream;

  /// The current search text, lower-cased
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _clientsStream = ref
        .read(firestoreServiceProvider)
        .streamActiveClientsByBranch(widget.currentUser.branchId);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FieldNoteModel>> notesAsyncValue =
        ref.watch(branchFieldNotesProvider(widget.currentUser.branchId));

    /// Badges simply stay empty while notes load or if they fail
    final List<FieldNoteModel> branchNotes =
        _activeNotes(notesAsyncValue.value ?? const []);

    return Column(
      children: [
        /// Search box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.l10n.diarySearchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                setState(() => _searchText = value.trim().toLowerCase()),
          ),
        ),

        /// Shown if the notes query fails (e.g. the index is still building)
        if (notesAsyncValue.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.diaryLoadFailed,
              style: TextStyle(color: context.colors.error, fontSize: 13),
            ),
          ),

        Expanded(
          child: StreamBuilder<List<ClientModel>>(
            stream: _clientsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _DiaryMessage(
                  icon: Icons.error_outline,
                  message: context.l10n.diaryLoadFailed,
                );
              }

              final List<ClientModel> clients = (snapshot.data ?? [])
                  .where((client) =>
                      client.clientName.toLowerCase().contains(_searchText))
                  .toList();

              if (clients.isEmpty) {
                return _DiaryMessage(
                  icon: Icons.business_outlined,
                  message: context.l10n.diaryNoBusinesses,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final ClientModel client = clients[index];
                  final List<FieldNoteModel> clientNotes = branchNotes
                      .where((note) => note.clientId == client.clientId)
                      .toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(Icons.business_outlined,
                          color: context.colors.primary),
                      title: Text(
                        client.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: clientNotes.isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: _NotesBadge(notes: clientNotes),
                              ),
                            ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        AppRoutePaths.diaryMachines,
                        extra: {
                          'currentUser': widget.currentUser,
                          'client': client,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 2. MACHINES OF A BUSINESS
// ─────────────────────────────────────────────

/// The Diary's second level: the machines (locations) of one business.
class DiaryMachinesScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final ClientModel client;

  const DiaryMachinesScreen({
    super.key,
    required this.currentUser,
    required this.client,
  });

  @override
  ConsumerState<DiaryMachinesScreen> createState() =>
      _DiaryMachinesScreenState();
}

class _DiaryMachinesScreenState extends ConsumerState<DiaryMachinesScreen> {
  late final Stream<List<LocationModel>> _machinesStream;

  @override
  void initState() {
    super.initState();
    _machinesStream =
        ref.read(firestoreServiceProvider).streamActiveLocationsByClient(
              branchId: widget.currentUser.branchId,
              clientId: widget.client.clientId,
            );
  }

  @override
  Widget build(BuildContext context) {
    final List<FieldNoteModel> branchNotes = _activeNotes(
      ref
              .watch(branchFieldNotesProvider(widget.currentUser.branchId))
              .value ??
          const [],
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.client.clientName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: StreamBuilder<List<LocationModel>>(
            stream: _machinesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _DiaryMessage(
                  icon: Icons.error_outline,
                  message: context.l10n.diaryLoadFailed,
                );
              }

              final List<LocationModel> machines = snapshot.data ?? [];
              if (machines.isEmpty) {
                return _DiaryMessage(
                  icon: Icons.precision_manufacturing_outlined,
                  message: context.l10n.diaryNoMachines,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: machines.length,
                itemBuilder: (context, index) {
                  final LocationModel machine = machines[index];
                  final List<FieldNoteModel> machineNotes = branchNotes
                      .where((note) => note.locationId == machine.locationId)
                      .toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(Icons.precision_manufacturing_outlined,
                          color: context.colors.primary),
                      title: Text(
                        machine.locationName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (machine.address.isNotEmpty)
                            Text(machine.address,
                                style: const TextStyle(fontSize: 13)),
                          if (machineNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _NotesBadge(notes: machineNotes),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        AppRoutePaths.diaryMachine,
                        extra: {
                          'currentUser': widget.currentUser,
                          'location': machine,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 3. ONE MACHINE: permanent info + recent notes
// ─────────────────────────────────────────────

/// The Diary's third level: one machine. Shows the manager's permanent
/// location notes ("Machine info") and the technicians' recent notes,
/// with a button to add a note.
class DiaryMachineScreen extends ConsumerWidget {
  final UserModel currentUser;
  final LocationModel location;

  const DiaryMachineScreen({
    super.key,
    required this.currentUser,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FieldNoteModel>> notesAsyncValue =
        ref.watch(branchFieldNotesProvider(currentUser.branchId));
    final int retentionDays = ref
            .watch(fieldNoteRetentionDaysProvider(currentUser.branchId))
            .value ??
        FirestoreService.defaultFieldNoteRetentionDays;

    final String title = location.clientName.isNotEmpty
        ? '${location.clientName}, ${location.locationName}'
        : location.locationName;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context, ref),
        icon: const Icon(Icons.edit_note),
        label: Text(context.l10n.diaryAddNote),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            /// Extra bottom room so the button never covers the last note
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              96 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              /// Permanent manager notes, only shown when there are some
              if (location.notes.isNotEmpty) ...[
                _SectionTitle(
                  icon: Icons.push_pin_outlined,
                  text: context.l10n.diaryMachineInfo,
                ),
                ...location.notes.map((NoteEntry note) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: context.colors.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          note.text,
                          style: TextStyle(
                            color: context.colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              /// Technicians' recent notes
              _SectionTitle(
                icon: Icons.menu_book_outlined,
                text: context.l10n.diaryRecentNotes(retentionDays),
              ),
              notesAsyncValue.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => _DiaryMessage(
                  icon: Icons.error_outline,
                  message: context.l10n.diaryLoadFailed,
                ),
                data: (List<FieldNoteModel> branchNotes) {
                  final List<FieldNoteModel> machineNotes =
                      _activeNotes(branchNotes)
                          .where((note) =>
                              note.locationId == location.locationId)
                          .toList();

                  if (machineNotes.isEmpty) {
                    return _DiaryMessage(
                      icon: Icons.note_alt_outlined,
                      message: context.l10n.diaryNoRecentNotes,
                    );
                  }

                  return Column(
                    children: machineNotes
                        .map((note) => _FieldNoteCard(
                              note: note,
                              canDelete: note.authorId == currentUser.userId ||
                                  currentUser.role == UserRole.manager,
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a dialog to write a new note on this machine.
  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    /// Dialog-local controller, deliberately not disposed (see handoff notes)
    final TextEditingController noteController = TextEditingController();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failedMessage = context.l10n.diaryNoteSaveFailed;
    final FirestoreService firestoreService = ref.read(firestoreServiceProvider);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final String text = noteController.text.trim();
            if (text.isEmpty || isSaving) return;
            setDialogState(() => isSaving = true);
            try {
              await firestoreService.addFieldNote(
                author: currentUser,
                location: location,
                text: text,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            } catch (error) {
              debugPrint('addFieldNote failed: $error');
              messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
              if (dialogContext.mounted) {
                setDialogState(() => isSaving = false);
              }
            }
          }

          return AlertDialog(
            title: Text(context.l10n.diaryAddNote),
            content: TextField(
              controller: noteController,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: FieldNoteModel.maxTextLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: context.l10n.diaryNoteHint,
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.diarySave),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bold heading with an icon, used for the two parts of the machine page.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One technician note: text, author, time, and delete when allowed.
class _FieldNoteCard extends ConsumerWidget {
  final FieldNoteModel note;
  final bool canDelete;

  const _FieldNoteCard({required this.note, required this.canDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color mutedColor = context.colors.onSurfaceVariant;
    final String details = [
      note.authorName,
      _formatNoteTime(context, note.createdAt),
      if (note.operationName != null && note.operationName!.isNotEmpty)
        note.operationName!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.text, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(details,
                      style: TextStyle(fontSize: 12, color: mutedColor)),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline, color: mutedColor),
                tooltip: context.l10n.diaryDelete,
                onPressed: () => _confirmDelete(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  /// Asks for confirmation, then deletes the note.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failedMessage = context.l10n.diaryNoteDeleteFailed;
    final FirestoreService firestoreService = ref.read(firestoreServiceProvider);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.diaryDeleteNoteTitle),
        content: Text(context.l10n.diaryDeleteNoteConfirm),
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
            child: Text(context.l10n.diaryDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await firestoreService.deleteFieldNote(note.noteId);
    } catch (error) {
      debugPrint('deleteFieldNote failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }
}
