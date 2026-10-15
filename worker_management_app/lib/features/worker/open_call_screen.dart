import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/app_theme.dart';
import '../../core/models/call_model.dart';
import '../../core/models/client_model.dart';
import '../../core/models/location_model.dart';
import '../../core/models/operation_type_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import '../../core/localization_extension.dart';
import '../shared/message_box.dart';

/// Screen where a worker opens a new work call.
/// The worker selects an operation type, a client and a location from
/// dropdowns, and can optionally set a manual start time.
class OpenCallScreen extends ConsumerStatefulWidget {
  const OpenCallScreen({super.key});

  @override
  ConsumerState<OpenCallScreen> createState() => _OpenCallScreenState();
}

class _OpenCallScreenState extends ConsumerState<OpenCallScreen> {
  /// Used to validate the form before submitting
  final GlobalKey<FormState> _openCallFormKey = GlobalKey<FormState>();

  /// The operation type selected by the worker from the dropdown
  OperationTypeModel? _selectedOperationType;

  /// The location selected by the worker from the dropdown
  LocationModel? _selectedLocation;

  /// The client selected by the worker from the first dropdown
  ClientModel? _selectedClient;

  /// The start time of the call, defaults to now but can be changed manually
  DateTime _selectedStartTime = DateTime.now();

  /// Whether the form submission is currently in progress
  bool _isSubmitting = false;

  /// Error message to display if submission fails
  String? _errorMessage;

  /// Opens a date and time picker so the worker can manually set the start time.
  Future<void> _pickStartTime() async {
    /// First pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    /// Then pick the time
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

  /// Creates a new call document in Firestore and navigates back to dashboard.
  Future<void> _submitOpenCall(UserModel currentUser) async {
    if (!_openCallFormKey.currentState!.validate()) return;

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

    /// The time picker allows any hour today - block a start in the future
    if (_selectedStartTime.isAfter(DateTime.now())) {
      setState(() => _errorMessage = context.l10n.timeCannotBeInFuture);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final FirestoreService firestoreService = ref.read(
        firestoreServiceProvider,
      );

      /// Generate a unique ID for the new call
      final String newCallId = const Uuid().v4();

      final CallModel newCall = CallModel(
        callId: newCallId,
        operationName: _selectedOperationType!.operationTypeName,
        locationName: _selectedLocation!.locationName,
        locationLatitude: _selectedLocation!.latitude,
        locationLongitude: _selectedLocation!.longitude,
        startTime: _selectedStartTime,
        status: CallStatus.open,
        workerUserId: currentUser.userId,
        workerFullName: currentUser.fullName,
        branchId: currentUser.branchId,
        clientId: _selectedClient!.clientId,
        clientName: _selectedClient!.clientName,
        closeForm: _selectedOperationType!.closeForm,
      );

      await firestoreService.createCall(newCall);

      /// Navigate back to the worker dashboard after successful submission.
      /// No setState after this - the screen is being removed.
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.failedToOpenCall;
        _isSubmitting = false;
      });
    }
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

  /// Called when the worker selects a client.
  /// Resets the location selection since locations are client-specific.
  void _onClientSelected(ClientModel? client) {
    setState(() {
      _selectedClient = client;
      _selectedLocation = null;
      _errorMessage = null;
    });
  }

  /// True only on a StreamBuilder's very first load.
  /// (Every setState here creates a fresh stream; checking hasData keeps
  /// the dropdowns visible instead of flashing a spinner each time.)
  bool _isFirstLoad(AsyncSnapshot snapshot) =>
      !snapshot.hasData && !snapshot.hasError;

  @override
  Widget build(BuildContext context) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

    return authenticatedUserAsyncValue.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _buildScreen(currentUser);
      },
    );
  }

  /// Builds the main screen content once the current user is loaded.
  Widget _buildScreen(UserModel currentUser) {
    final FirestoreService firestoreService = ref.read(
      firestoreServiceProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.openNewCall)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            /// Extra bottom padding keeps the last button above the Android
            /// navigation bar (the app draws edge-to-edge behind it)
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Form(
              key: _openCallFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Operation type dropdown populated from Firestore
                  StreamBuilder<List<OperationTypeModel>>(
                    stream: firestoreService.streamActiveOperationTypesByBranch(
                      currentUser.branchId,
                    ),
                    builder: (context, snapshot) {
                      if (_isFirstLoad(snapshot)) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<OperationTypeModel> availableOperationTypes =
                          snapshot.data ?? [];

                      if (availableOperationTypes.isEmpty) {
                        return MessageBox.warning(
                          context.l10n.noOperationTypesAvailable,
                        );
                      }

                      return DropdownButtonFormField<OperationTypeModel>(
                        /// Guard: if the selected item was deleted meanwhile, show nothing
                        /// instead of crashing ("exactly one item with value")
                        value:
                            availableOperationTypes.contains(
                              _selectedOperationType,
                            )
                            ? _selectedOperationType
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.operationType,
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        items: availableOperationTypes.map((operationType) {
                          return DropdownMenuItem<OperationTypeModel>(
                            value: operationType,
                            child: Text(
                              operationType.operationTypeName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (OperationTypeModel? selectedType) {
                          setState(() {
                            _selectedOperationType = selectedType;
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
                      currentUser.branchId,
                    ),
                    builder: (context, snapshot) {
                      if (_isFirstLoad(snapshot)) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<ClientModel> availableClients =
                          snapshot.data ?? [];

                      if (availableClients.isEmpty) {
                        return MessageBox.warning(
                          context.l10n.noClientsCreated,
                        );
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

                  /// Location dropdown - only shown when a client is selected.
                  /// The key makes it start fresh for each client, so the
                  /// previous client's locations never show up for a moment.
                  if (_selectedClient != null) ...[
                    StreamBuilder<List<LocationModel>>(
                      key: ValueKey(_selectedClient!.clientId),
                      stream: firestoreService.streamActiveLocationsByClient(
                        branchId: currentUser.branchId,
                        clientId: _selectedClient!.clientId,
                      ),
                      builder: (context, snapshot) {
                        if (_isFirstLoad(snapshot)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<LocationModel> availableLocations =
                            snapshot.data ?? [];

                        if (availableLocations.isEmpty) {
                          return MessageBox.warning(
                            context.l10n.noLocationsForClient,
                          );
                        }

                        return DropdownButtonFormField<LocationModel>(
                          value: availableLocations.contains(_selectedLocation)
                              ? _selectedLocation
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.l10n.selectLocation,
                            prefixIcon: const Icon(Icons.location_on_outlined),
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
                          onChanged: (LocationModel? selectedLocation) {
                            setState(() {
                              _selectedLocation = selectedLocation;
                              _errorMessage = null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  /// Manual start time picker - styled like the other fields
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

                  /// Error message display
                  if (_errorMessage != null) ...[
                    MessageBox.error(_errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  /// Submit button - colors come from the theme
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitOpenCall(currentUser),
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
                              context.l10n.openCall,
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
