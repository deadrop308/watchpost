import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app_theme.dart';
import '../../../app/router.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/client_model.dart';
import '../../../core/models/location_model.dart';
import '../../../core/models/note_entry_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_service.dart';
import 'notes_section.dart';

/// Screen where a manager manages clients and their locations.
/// Wide screens: clients on the left, locations on the right.
/// Narrow screens (phones): clients on top, locations below.
/// Tapping a client shows its notes and its locations.
class ClientsAndLocationsScreen extends ConsumerWidget {
  const ClientsAndLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

    return authenticatedUserAsyncValue.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _ClientsAndLocationsContent(currentUser: currentUser);
      },
    );
  }
}

class _ClientsAndLocationsContent extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const _ClientsAndLocationsContent({required this.currentUser});

  @override
  ConsumerState<_ClientsAndLocationsContent> createState() =>
      _ClientsAndLocationsContentState();
}

class _ClientsAndLocationsContentState
    extends ConsumerState<_ClientsAndLocationsContent> {
  /// The currently selected client to show locations for
  ClientModel? _selectedClient;

  /// Builds a new note entry stamped with the current time and manager name.
  NoteEntry _createNoteEntry(String text) {
    return NoteEntry(
      noteId: const Uuid().v4(),
      text: text,
      createdAt: DateTime.now(),
      authorName: widget.currentUser.fullName,
    );
  }

  /// Opens a dialog to add or edit a client.
  Future<void> _showClientDialog(
      BuildContext context, {
        ClientModel? existingClient,
      }) async {
    /// Local controller — not disposed manually (see SPEC: dialog controllers)
    final TextEditingController clientNameController =
    TextEditingController(text: existingClient?.clientName ?? '');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          /// Saves the client. isSaving blocks a double tap from
          /// creating the same client twice.
          Future<void> save() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => isSaving = true);
            try {
              if (existingClient == null) {
                await firestoreService.createClient(ClientModel(
                  clientId: const Uuid().v4(),
                  clientName: clientNameController.text.trim(),
                  branchId: widget.currentUser.branchId,
                  createdAt: DateTime.now(),
                  isActive: true,
                ));
              } else {
                await firestoreService.updateClientName(
                  clientId: existingClient.clientId,
                  newClientName: clientNameController.text.trim(),
                );
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            } catch (error) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.failedToSaveClient),
                    backgroundColor: context.colors.error,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            title: Text(
              existingClient == null
                  ? context.l10n.addClient
                  : context.l10n.editClient,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: clientNameController,
                maxLength: 40,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => save(),
                decoration: InputDecoration(
                  labelText: context.l10n.clientName,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.pleaseEnterClientName;
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              /// Colors come from the theme
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: Text(context.l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a client.
  Future<void> _confirmDeleteClient(
      BuildContext context,
      ClientModel clientToDelete,
      ) async {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteClient),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestoreService
                    .deactivateClient(clientToDelete.clientId);
                if (mounted &&
                    _selectedClient?.clientId == clientToDelete.clientId) {
                  setState(() => _selectedClient = null);
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.failedToDeleteClient),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a location.
  Future<void> _confirmDeleteLocation(
      BuildContext context,
      LocationModel locationToDelete,
      ) async {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteLocation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestoreService
                    .deactivateLocation(locationToDelete.locationId);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.failedToDeleteLocation),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    final Color mutedColor = context.colors.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.clientsAndLocations),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(
            builder: (context, constraints) {
              /// On phones, side-by-side panels are too narrow for the
              /// edit/delete buttons — stack them instead
              final bool isNarrow = constraints.maxWidth < 700;

              return Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Left panel — Clients list
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        /// Clients header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.clients,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.addClient,
                                icon: Icon(Icons.add_circle_outline,
                                    color: context.colors.primary),
                                onPressed: () => _showClientDialog(context),
                              ),
                            ],
                          ),
                        ),

                        /// Clients stream
                        Expanded(
                          child: StreamBuilder<List<ClientModel>>(
                            stream: firestoreService.streamActiveClientsByBranch(
                              widget.currentUser.branchId,
                            ),
                            builder: (context, snapshot) {
                              /// Spinner only on the very first load
                              if (!snapshot.hasData && !snapshot.hasError) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final List<ClientModel> clients =
                                  snapshot.data ?? [];

                              /// Keep the selected client up to date — after a
                              /// rename, new locations must get the NEW name
                              if (_selectedClient != null) {
                                for (final ClientModel client in clients) {
                                  if (client.clientId ==
                                      _selectedClient!.clientId) {
                                    _selectedClient = client;
                                    break;
                                  }
                                }
                              }

                              if (clients.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      context.l10n.noClientsCreated,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: mutedColor),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: clients.length,
                                itemBuilder: (context, index) {
                                  final ClientModel client = clients[index];
                                  final bool isSelected =
                                      _selectedClient?.clientId ==
                                          client.clientId;

                                  return Card(
                                    key: ValueKey(client.clientId),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: isSelected ? 4 : 1,
                                    /// null = normal card color from the theme
                                    color: isSelected
                                        ? context.colors.primaryContainer
                                        : null,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: isSelected
                                          ? BorderSide(
                                          color: context.colors.primary,
                                          width: 1.5)
                                          : BorderSide.none,
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            client.clientName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          onTap: () => setState(() =>
                                          _selectedClient =
                                          isSelected ? null : client),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: context.l10n.editClient,
                                                icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: context.colors.primary,
                                                    size: 20),
                                                onPressed: () =>
                                                    _showClientDialog(
                                                      context,
                                                      existingClient: client,
                                                    ),
                                              ),
                                              IconButton(
                                                tooltip: context.l10n.delete,
                                                icon: Icon(
                                                    Icons.delete_outline,
                                                    color: context.colors.error,
                                                    size: 20),
                                                onPressed: () =>
                                                    _confirmDeleteClient(
                                                        context, client),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// Client notes — only shown for the
                                        /// selected client to keep the list compact
                                        if (isSelected)
                                          NotesSection(
                                            ownerId: client.clientId,
                                            notes: client.notes,
                                            onAddNote: (text) =>
                                                firestoreService.addClientNote(
                                                  clientId: client.clientId,
                                                  note: _createNoteEntry(text),
                                                ),
                                            onDeleteNote: (note) =>
                                                firestoreService.deleteClientNote(
                                                  clientId: client.clientId,
                                                  noteId: note.noteId,
                                                ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isNarrow)
                    const Divider(height: 1)
                  else
                    const VerticalDivider(width: 1),

                  /// Right panel — Locations for selected client
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        /// Locations header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.locations,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedClient != null)
                                IconButton(
                                  tooltip: context.l10n.addLocation,
                                  icon: Icon(Icons.add_circle_outline,
                                      color: context.colors.primary),
                                  onPressed: () => context.push(
                                    AppRoutePaths.managerAddEditLocation,
                                    extra: {
                                      'currentUser': widget.currentUser,
                                      'existingLocation': null,
                                      'selectedClient': _selectedClient,
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        /// Locations content
                        Expanded(
                          child: _selectedClient == null
                              ? Center(
                            child: Text(
                              context.l10n.selectClient,
                              style: TextStyle(color: mutedColor),
                            ),
                          )
                              : StreamBuilder<List<LocationModel>>(
                            /// Fresh for each client — the previous client's
                            /// locations never flash up
                            key: ValueKey(_selectedClient!.clientId),
                            stream: firestoreService
                                .streamActiveLocationsByClient(
                              branchId: widget.currentUser.branchId,
                              clientId: _selectedClient!.clientId,
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData && !snapshot.hasError) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final List<LocationModel> locations =
                                  snapshot.data ?? [];

                              if (locations.isEmpty) {
                                return Center(
                                  child: Text(
                                    context.l10n.noLocationsForClient,
                                    style: TextStyle(color: mutedColor),
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                itemCount: locations.length,
                                itemBuilder: (context, index) {
                                  final LocationModel location =
                                  locations[index];
                                  return Card(
                                    key: ValueKey(location.locationId),
                                    margin:
                                    const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                              Icons.location_on_outlined,
                                              color: context.colors.primary),
                                          title:
                                          Text(location.locationName),
                                          subtitle: location
                                              .address.isNotEmpty
                                              ? Text(
                                            location.address,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: mutedColor),
                                          )
                                              : null,
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: context.l10n.editLocation,
                                                icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: context.colors.primary,
                                                    size: 20),
                                                onPressed: () =>
                                                    context.push(
                                                      AppRoutePaths
                                                          .managerAddEditLocation,
                                                      extra: {
                                                        'currentUser':
                                                        widget.currentUser,
                                                        'existingLocation':
                                                        location,
                                                        'selectedClient':
                                                        _selectedClient,
                                                      },
                                                    ),
                                              ),
                                              IconButton(
                                                tooltip: context.l10n.delete,
                                                icon: Icon(
                                                    Icons.delete_outline,
                                                    color: context.colors.error,
                                                    size: 20),
                                                onPressed: () =>
                                                    _confirmDeleteLocation(
                                                        context, location),
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// Location notes
                                        NotesSection(
                                          ownerId: location.locationId,
                                          notes: location.notes,
                                          onAddNote: (text) =>
                                              firestoreService
                                                  .addLocationNote(
                                                locationId:
                                                location.locationId,
                                                note: _createNoteEntry(text),
                                              ),
                                          onDeleteNote: (note) =>
                                              firestoreService
                                                  .deleteLocationNote(
                                                locationId:
                                                location.locationId,
                                                noteId: note.noteId,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}