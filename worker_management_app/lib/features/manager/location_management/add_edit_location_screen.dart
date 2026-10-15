import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app_theme.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/location_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/places_service.dart';
import '../../../core/models/client_model.dart';
import '../../shared/message_box.dart';

/// Screen for adding a new location or editing an existing one.
/// Uses Google Places autocomplete for address search.
class AddEditLocationScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final LocationModel? existingLocation;
  /// The client this location belongs to
  final ClientModel? selectedClient;

  const AddEditLocationScreen({
    super.key,
    required this.currentUser,
    this.existingLocation,
    this.selectedClient,
  });

  @override
  ConsumerState<AddEditLocationScreen> createState() =>
      _AddEditLocationScreenState();
}

class _AddEditLocationScreenState
    extends ConsumerState<AddEditLocationScreen> {
  /// Controls the location name input field
  final TextEditingController _locationNameController =
  TextEditingController();

  /// Controls the address search input field
  final TextEditingController _addressController = TextEditingController();

  /// The Places service for autocomplete and place details
  late final PlacesService _placesService;

  /// Current autocomplete suggestions
  List<PlaceSuggestion> _suggestions = [];

  /// Whether autocomplete suggestions are currently loading
  bool _isLoadingSuggestions = false;

  /// The selected place details
  String _selectedAddress = '';
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;

  /// Whether a place has been selected from the suggestions
  bool _placeSelected = false;

  /// Whether the form submission is currently in progress
  bool _isSubmitting = false;

  /// Error message to display if submission fails
  String? _errorMessage;

  /// Debounce timer for autocomplete requests
  DateTime? _lastTypedTime;

  /// Used to validate the form before submitting
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService();

    /// Pre-fill fields if editing an existing location
    if (widget.existingLocation != null) {
      _locationNameController.text = widget.existingLocation!.locationName;
      _addressController.text = widget.existingLocation!.address;
      _selectedAddress = widget.existingLocation!.address;
      _selectedLatitude = widget.existingLocation!.latitude;
      _selectedLongitude = widget.existingLocation!.longitude;
      _placeSelected = widget.existingLocation!.address.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Called when the address field text changes.
  /// Debounces the autocomplete request by 400ms.
  Future<void> _onAddressChanged(String inputText) async {
    /// Clear selection when user types again
    setState(() {
      _placeSelected = false;
      _selectedAddress = '';
      _selectedLatitude = 0.0;
      _selectedLongitude = 0.0;
    });

    if (inputText.length < 3) {
      /// Also cancels any search still loading for the longer text
      _lastTypedTime = DateTime.now();
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    _lastTypedTime = DateTime.now();
    final DateTime typedTime = _lastTypedTime!;

    /// Wait 400ms before making the API call
    await Future.delayed(const Duration(milliseconds: 400));

    /// If the user typed again during the delay (or left), skip this request
    if (!mounted || _lastTypedTime != typedTime) return;

    setState(() => _isLoadingSuggestions = true);

    List<PlaceSuggestion> suggestions = [];
    try {
      suggestions =
      await _placesService.fetchAutocompleteSuggestions(inputText);
    } catch (_) {
      /// Network / API error — just show no suggestions
    }

    /// A newer search may have started while this one was loading —
    /// don't let this older answer overwrite it
    if (!mounted || _lastTypedTime != typedTime) return;

    setState(() {
      _suggestions = suggestions;
      _isLoadingSuggestions = false;
    });
  }

  /// Called when the user selects a suggestion from the dropdown.
  /// Fetches the place details including coordinates.
  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    setState(() {
      _addressController.text = suggestion.description;
      _suggestions = [];
      _isLoadingSuggestions = true;
    });

    /// Stop any pending autocomplete answer from reopening the list
    _lastTypedTime = DateTime.now();

    PlaceDetails? fetchedDetails;
    try {
      fetchedDetails =
      await _placesService.fetchPlaceDetails(suggestion.placeId);
    } catch (_) {
      /// Network / API error — treated like "no details"
    }

    if (!mounted) return;

    /// A final copy, so Dart knows it can't turn null inside setState
    final PlaceDetails? details = fetchedDetails;

    if (details != null) {
      setState(() {
        _selectedAddress = details.formattedAddress;
        _selectedLatitude = details.latitude;
        _selectedLongitude = details.longitude;
        _placeSelected = true;
        _isLoadingSuggestions = false;
      });
    } else {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  /// Saves the location to Firestore and navigates back.
  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_placeSelected) {
      setState(() {
        _errorMessage = context.l10n.pleaseSelectAddress;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final FirestoreService firestoreService =
      ref.read(firestoreServiceProvider);

      if (widget.existingLocation == null) {
        final LocationModel newLocation = LocationModel(
          locationId: const Uuid().v4(),
          locationName: _locationNameController.text.trim(),
          branchId: widget.currentUser.branchId,
          createdAt: DateTime.now(),
          isActive: true,
          address: _selectedAddress,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          clientId: widget.selectedClient?.clientId ?? '',
          clientName: widget.selectedClient?.clientName ?? '',
        );
        await firestoreService.createLocation(newLocation);
      } else {
        await firestoreService.updateLocation(
          locationId: widget.existingLocation!.locationId,
          newLocationName: _locationNameController.text.trim(),
          newAddress: _selectedAddress,
          newLatitude: _selectedLatitude,
          newLongitude: _selectedLongitude,
        );
      }

      /// No setState after this — the screen is being removed
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.failedToSaveLocation;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? context.l10n.editLocation : context.l10n.addLocation,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Location name input
                  TextFormField(
                    controller: _locationNameController,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: context.l10n.locationName,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.pleaseEnterLocationName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// Address search field with autocomplete
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: context.l10n.address,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _isLoadingSuggestions
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      )
                          : _placeSelected
                          ? Icon(Icons.check_circle,
                          color: Colors.green[600])
                          : null,
                    ),
                    onChanged: _onAddressChanged,
                  ),

                  /// Autocomplete suggestions dropdown
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        /// Same color as cards: white light / dark grey dark
                        color: Theme.of(context).cardTheme.color ??
                            context.colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final PlaceSuggestion suggestion =
                          _suggestions[index];
                          return ListTile(
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: context.colors.primary,
                              size: 20,
                            ),
                            title: Text(
                              suggestion.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () =>
                                _onSuggestionSelected(suggestion),
                          );
                        },
                      ),
                    ),

                  /// Show selected coordinates if available
                  if (_placeSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        context.l10n.selectedAddressLabel(_selectedAddress),
                        style: TextStyle(
                          fontSize: 12,
                          /// Readable green in both themes
                          color: Theme.of(context).brightness ==
                              Brightness.dark
                              ? Colors.green[300]
                              : Colors.green[700],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  /// Error message
                  if (_errorMessage != null) ...[
                    MessageBox.error(_errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  /// Save button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitLocation,
                      /// Colors come from the theme
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
                          : Text(context.l10n.save),
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