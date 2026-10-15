import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/app_theme.dart';
import '../../core/localization_extension.dart';
import '../../core/models/call_model.dart';
import '../../core/models/client_model.dart';
import '../../core/models/location_model.dart';
import '../../core/models/operation_type_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import '../shared/message_box.dart';

/// Screen where a manager assigns a call to a specific worker.
/// The call appears on the worker's dashboard under their name,
/// and the worker receives a push notification.
class SendCallScreen extends ConsumerStatefulWidget {
  const SendCallScreen({super.key});

  @override
  ConsumerState<SendCallScreen> createState() => _SendCallScreenState();
}

class _SendCallScreenState extends ConsumerState<SendCallScreen> {
  /// Controls the instructions input field
  final TextEditingController _instructionsController =
  TextEditingController();

  /// Used to validate the form before submitting
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// The selected worker to assign the call to
  UserModel? _selectedWorker;

  /// The selected operation type
  OperationTypeModel? _selectedOperationType;

  /// The selected location
  LocationModel? _selectedLocation;

  /// The client selected from the first dropdown
  ClientModel? _selectedClient;

  /// The start time of the call, defaults to now
  DateTime _selectedStartTime = DateTime.now();

  /// Whether the form is currently submitting
  bool _isSubmitting = false;

  /// Error message to display if submission fails
  String? _errorMessage;

  /// Branch members, fetched ONCE. Before, the fetch ran again on every
  /// setState (every dropdown pick) — extra Firestore reads + a spinner.
  Future<List<UserModel>>? _branchMembersFuture;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  /// Formats a [DateTime] into a readable string for display.
  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// "Dana Cohen" for workers, "Avi Levi (Manager)" for managers.
  String _memberLabel(UserModel member) {
    if (member.role == UserRole.manager) {
      return '${member.fullName} (${context.l10n.roleManager})';
    }
    return member.fullName;
  }

  /// True only on a StreamBuilder's very first load.
  bool _isFirstLoad(AsyncSnapshot snapshot) =>
      !snapshot.hasData && !snapshot.hasError;

  /// Called when the manager selects a client.
  /// Resets the location selection since locations are client-specific.
  void _onClientSelected(ClientModel? client) {
    setState(() {
      _selectedClient = client;
      _selectedLocation = null;
      _errorMessage = null;
    });
  }

  /// Opens a date and time picker for the start time.
  Future<void> _pickStartTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedStartTime),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _errorMessage = null;
    });
  }

  /// Creates the call in Firestore under the selected worker's name,
  /// returns to the dashboard immediately, and sends the push
  /// notification in the background.
  Future<void> _submitSendCall(UserModel currentManager) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWorker == null) {
      setState(() => _errorMessage = context.l10n.pleaseSelectWorker);
      return;
    }
    if (_selectedOperationType == null) {
      setState(() => _errorMessage = context.l10n.pleaseSelectOperationType);
      return;
    }
    if (_selectedClient == null) {
      setState(() => _errorMessage = context.l10n.pleaseSelectClient);
      return;
    }
    if (_selectedLocation == null) {
      setState(() => _errorMessage = context.l10n.pleaseSelectLocation);
      return;
    }

    /// The time picker allows any hour today — block a start in the future
    if (_selectedStartTime.isAfter(DateTime.now())) {
      setState(() => _errorMessage = context.l10n.timeCannotBeInFuture);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);
    final CloudFunctionsService cloudFunctionsService =
    ref.read(cloudFunctionsServiceProvider);

    /// Capture all values now — the screen closes before the
    /// background notification runs, so we can't read state later
    final String workerUserId = _selectedWorker!.userId;
    final String operationName = _selectedOperationType!.operationTypeName;
    final String locationName = _selectedLocation!.locationName;
    final String instructions = _instructionsController.text.trim();

    try {
      final CallModel assignedCall = CallModel(
        callId: const Uuid().v4(),
        operationName: operationName,
        locationName: locationName,
        locationLatitude: _selectedLocation!.latitude,
        locationLongitude: _selectedLocation!.longitude,
        startTime: _selectedStartTime,
        status: CallStatus.open,
        workerUserId: workerUserId,
        workerFullName: _selectedWorker!.fullName,
        branchId: currentManager.branchId,
        assignedByManagerId: currentManager.userId,
        clientId: _selectedClient!.clientId,
        clientName: _selectedClient!.clientName,
        managerInstructions: instructions.isEmpty ? null : instructions,
        closeForm: _selectedOperationType!.closeForm,
      );

      /// Wait only for the Firestore write — this is fast and
      /// confirms the call actually exists before we leave the screen
      await firestoreService.createCall(assignedCall);

      if (!mounted) return;

      /// Return to the dashboard immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.callAssignedSuccess),
          backgroundColor: Colors.green[700],
        ),
      );
      context.pop();

      /// Send the push notification in the background — not awaited.
      /// If it fails, the call still exists on the worker's dashboard.
      cloudFunctionsService
          .sendCallAssignmentNotification(
        workerUserId: workerUserId,
        operationName: operationName,
        locationName: locationName,
        managerInstructions: instructions,
      )
          .catchError((Object error) {
        debugPrint('Failed to send call notification: $error');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.failedToAssignCall;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        return _buildScreen(currentUser);
      },
    );
  }

  Widget _buildScreen(UserModel currentManager) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    /// Fetch branch members only the first time
    _branchMembersFuture ??=
        firestoreService.fetchAllBranchMembers(currentManager.branchId);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sendCallTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Worker selection dropdown
                  FutureBuilder<List<UserModel>>(
                    future: _branchMembersFuture,
                    builder: (context, snapshot) {
                      if (_isFirstLoad(snapshot)) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final List<UserModel> branchMembers =
                          snapshot.data ?? [];

                      return DropdownButtonFormField<UserModel>(
                        value: branchMembers.contains(_selectedWorker)
                            ? _selectedWorker
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.selectWorker,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        items: branchMembers.map((member) {
                          return DropdownMenuItem<UserModel>(
                            value: member,
                            child: Text(
                              _memberLabel(member),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (UserModel? selected) {
                          setState(() {
                            _selectedWorker = selected;
                            _errorMessage = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Operation type dropdown
                  StreamBuilder<List<OperationTypeModel>>(
                    stream: firestoreService
                        .streamActiveOperationTypesByBranch(
                      currentManager.branchId,
                    ),
                    builder: (context, snapshot) {
                      if (_isFirstLoad(snapshot)) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final List<OperationTypeModel> operationTypes =
                          snapshot.data ?? [];

                      if (operationTypes.isEmpty) {
                        return MessageBox.warning(
                            context.l10n.noOperationTypesAvailable);
                      }

                      return DropdownButtonFormField<OperationTypeModel>(
                        value: operationTypes.contains(_selectedOperationType)
                            ? _selectedOperationType
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.operationType,
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        items: operationTypes.map((type) {
                          return DropdownMenuItem<OperationTypeModel>(
                            value: type,
                            child: Text(
                              type.operationTypeName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (OperationTypeModel? selected) {
                          setState(() {
                            _selectedOperationType = selected;
                            _errorMessage = null;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Client dropdown
                  StreamBuilder<List<ClientModel>>(
                    stream: firestoreService.streamActiveClientsByBranch(
                      currentManager.branchId,
                    ),
                    builder: (context, snapshot) {
                      if (_isFirstLoad(snapshot)) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<ClientModel> availableClients =
                          snapshot.data ?? [];

                      if (availableClients.isEmpty) {
                        return MessageBox.warning(
                            context.l10n.noClientsCreated);
                      }

                      return DropdownButtonFormField<ClientModel>(
                        value: availableClients.contains(_selectedClient)
                            ? _selectedClient
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.selectClient,
                          prefixIcon: const Icon(Icons.business_outlined),
                        ),
                        items: availableClients.map((client) {
                          return DropdownMenuItem<ClientModel>(
                            value: client,
                            child: Text(
                              client.clientName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onClientSelected,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Location dropdown — only shown when a client is selected.
                  /// The key makes it start fresh for each client.
                  if (_selectedClient != null) ...[
                    StreamBuilder<List<LocationModel>>(
                      key: ValueKey(_selectedClient!.clientId),
                      stream: firestoreService.streamActiveLocationsByClient(
                        branchId: currentManager.branchId,
                        clientId: _selectedClient!.clientId,
                      ),
                      builder: (context, snapshot) {
                        if (_isFirstLoad(snapshot)) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final List<LocationModel> availableLocations =
                            snapshot.data ?? [];

                        if (availableLocations.isEmpty) {
                          return MessageBox.warning(
                              context.l10n.noLocationsForClient);
                        }

                        return DropdownButtonFormField<LocationModel>(
                          value: availableLocations.contains(_selectedLocation)
                              ? _selectedLocation
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.l10n.selectLocation,
                            prefixIcon:
                            const Icon(Icons.location_on_outlined),
                          ),
                          items: availableLocations.map((location) {
                            return DropdownMenuItem<LocationModel>(
                              value: location,
                              child: Text(
                                location.locationName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (LocationModel? selected) {
                            setState(() {
                              _selectedLocation = selected;
                              _errorMessage = null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  /// Manual start time picker — styled like the other fields
                  InkWell(
                    onTap: _pickStartTime,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.l10n.startTime,
                        prefixIcon: const Icon(Icons.access_time_outlined),
                        suffixIcon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      child: Text(
                        _formatDateTime(_selectedStartTime),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Manager instructions field
                  TextFormField(
                    controller: _instructionsController,
                    maxLength: 300,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: context.l10n.managerInstructions,
                      prefixIcon: const Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Error message
                  if (_errorMessage != null) ...[
                    MessageBox.error(_errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  /// Submit button — colors come from the theme
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitSendCall(currentManager),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        context.l10n.sendCall,
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
    );
  }
}